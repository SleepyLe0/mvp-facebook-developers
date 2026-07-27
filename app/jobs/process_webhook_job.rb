class ProcessWebhookJob < ApplicationJob
  queue_as :default

  MENU_PAYLOADS = %w[GET_STARTED CHECK_ORDER TALK_TO_HUMAN].freeze

  def perform(flow_type, payload)
    log = WebhookLog.create!(
      event_type: flow_type,
      payload: payload.to_json,
      status: "processing"
    )

    client = MetaGraphClient.new

    entries = payload["entry"] || []
    entries.each do |entry|
      entry_page_id = entry["id"]
      connected_page = ConnectedPage.find_by(page_id: entry_page_id)
      page_access_token = connected_page&.access_token

      messaging_events = entry["messaging"] || []
      messaging_events.each do |event|
        sender_id = event.dig("sender", "id")
        recipient_id = event.dig("recipient", "id")
        message_data = event["message"]

        # Get Started button and Persistent Menu taps arrive as postbacks (no message).
        if (postback = event["postback"])
          next if sender_id.blank?
          handle_menu_action(client, sender_id, postback["payload"], page_access_token)
          next
        end

        next if message_data.nil?

        # Boss Requirement #4: Support Message Echoes (messages sent by Page Admin or other apps)
        if message_data["is_echo"]
          echo_text = message_data["text"]
          app_id_source = message_data["app_id"] || "Page Inbox / Admin"

          Rails.logger.info "[ProcessWebhookJob] Received Message Echo from #{app_id_source}: #{echo_text}"

          # Record Echo into Support Ticket history for operator visibility
          ticket = SupportTicket.find_or_initialize_by(psid: recipient_id)
          ticket.last_message = "💬 [Echo from #{app_id_source}]: #{echo_text}"
          ticket.save!
          next
        end

        next if sender_id.blank?
        message_text = message_data.dig("quick_reply", "payload") || message_data["text"]
        next if message_text.blank?

        case flow_type.to_s
        when "unified"
          if MENU_PAYLOADS.include?(message_text)
            handle_menu_action(client, sender_id, message_text, page_access_token)
          else
            process_unified(client, sender_id, message_text, page_access_token)
          end
        when "faq"
          process_faq(client, sender_id, message_text, page_access_token)
        when "orders"
          process_orders(client, sender_id, message_text, page_access_token)
        when "profiles"
          process_profiles(client, sender_id, message_text, page_access_token)
        when "onboarding"
          process_onboarding(client, sender_id, message_text, page_access_token)
        else
          Rails.logger.info "[ProcessWebhookJob] Unknown flow type: #{flow_type}"
        end
      end
    end

    log.update!(status: "completed")
  rescue StandardError => e
    Rails.logger.error "[ProcessWebhookJob] Error: #{e.message}\n#{e.backtrace.join("\n")}"
    log&.update!(status: "failed", error_message: e.message)
  end

  private

  # Unified support flow: FAQ auto-reply → order lookup → human fallback.
  # This is the single endpoint used in production (/webhook).
  def process_unified(client, sender_id, text, access_token)
    # Bot takeover: a human is handling this conversation → record + stay silent.
    existing = SupportTicket.find_by(psid: sender_id)
    if existing&.handled_by_human
      existing.update!(last_message: text, last_customer_message_at: Time.current, status: "open")
      return
    end

    # 1. FAQ rule match → instant auto-reply (no tag).
    faq = FaqEntry.search_answer(text)
    if faq
      client.send_message(sender_id, { text: faq.answer }, access_token: access_token)
      return
    end

    # 2. Order number match → order status (no tag).
    order = Order.find_by_query(text)
    if order
      reply_text = "📦 Order #{order.order_number} Status: #{order.status.upcase}. Customer: #{order.customer_name}. Items: #{order.item_details}."
      client.send_message(sender_id, { text: reply_text }, access_token: access_token)
      return
    end

    # 3. No match → escalate to a human (plain ack, NO HUMAN_AGENT tag).
    escalate_to_human(client, sender_id, text, access_token)
  end

  # Welcome screen: Get Started button and Persistent Menu taps land here.
  def handle_menu_action(client, sender_id, payload, access_token)
    case payload
    when "CHECK_ORDER"
      client.send_message(sender_id, { text: "Sure! Please send your order number (for example, 1001)." }, access_token: access_token)
    when "TALK_TO_HUMAN"
      escalate_to_human(client, sender_id, "Requested a human agent", access_token)
    else # GET_STARTED or anything unknown
      send_welcome(client, sender_id, access_token)
    end
  end

  def send_welcome(client, sender_id, access_token)
    quick_replies = [
      { content_type: "text", title: "Check an order", payload: "CHECK_ORDER" },
      { content_type: "text", title: "Talk to a human", payload: "TALK_TO_HUMAN" }
    ]
    text = "👋 Welcome! I can answer common questions and check your order status. Ask me anything, or pick an option below."
    client.send_message(sender_id, { text: text, quick_replies: quick_replies }, access_token: access_token)
  end

  # Create/refresh a human ticket and send a plain acknowledgement (never tagged).
  def escalate_to_human(client, sender_id, text, access_token)
    ticket = SupportTicket.find_or_initialize_by(psid: sender_id)
    ticket.last_message = text
    ticket.status = "open"
    ticket.last_customer_message_at = Time.current
    ticket.save!
    ack = "Thanks for reaching out. I've passed this to our support team — a human agent will personally review your message and reply within 1–3 business days. (Ticket ##{ticket.id})"
    client.send_message(sender_id, { text: ack }, access_token: access_token)
  end

  # Flow 1: FAQ Auto-Responder
  def process_faq(client, sender_id, text, access_token)
    matched_faq = FaqEntry.search_answer(text)
    reply_text = matched_faq ? matched_faq.answer : "Hello! I'm the FAQ Auto-Responder Bot. How can I help you today?"

    quick_replies = [
      { content_type: "text", title: "Store Hours", payload: "hours" },
      { content_type: "text", title: "Location", payload: "location" },
      { content_type: "text", title: "Pricing", payload: "pricing" }
    ]

    message_payload = { text: reply_text, quick_replies: quick_replies }
    client.send_message(sender_id, message_payload, access_token: access_token)
  end

  # Flow 2: Order Inquiry & Human Handoff
  def process_orders(client, sender_id, text, access_token)
    # Bot takeover: if a human agent is handling this conversation, record the
    # message but stay silent — the bot must not butt in mid-handoff (UChat-style).
    existing = SupportTicket.find_by(psid: sender_id)
    if existing&.handled_by_human
      existing.update!(last_message: text, last_customer_message_at: Time.current, status: "open")
      return
    end

    order = Order.find_by_query(text)

    if order
      reply_text = "📦 Order #{order.order_number} Status: #{order.status.upcase}. Customer: #{order.customer_name}. Items: #{order.item_details}."
      client.send_message(sender_id, { text: reply_text }, access_token: access_token)
    else
      ticket = SupportTicket.find_or_initialize_by(psid: sender_id)
      ticket.last_message = text
      ticket.status = "open"
      ticket.last_customer_message_at = Time.current
      ticket.save!

      # Automated acknowledgement only — NO HUMAN_AGENT tag. This is an instant
      # bot reply inside the 24h window. The tag is reserved for the human agent
      # replying from the operator desk (Meta policy: tag must be human-sent).
      reply_text = "Thanks for reaching out. I've passed this to our support team — a human agent will personally review your message and reply within 1–3 business days. (Ticket ##{ticket.id})"
      client.send_message(sender_id, { text: reply_text }, access_token: access_token)
    end
  end

  # Flow 3: Profile Lookup
  def process_profiles(client, sender_id, text, access_token)
    profile_data = client.get_user_profile(sender_id, access_token: access_token)

    if profile_data && profile_data["first_name"].present?
      first_name = profile_data["first_name"]
      last_name = profile_data["last_name"]
      pic = profile_data["profile_pic"]
      locale = profile_data["locale"]

      user_profile = UserProfile.find_or_initialize_by(psid: sender_id)
      user_profile.update!(first_name: first_name, last_name: last_name, profile_pic: pic, locale: locale)

      reply_text = "Nice to meet you, #{first_name}! We fetched your profile details using Meta's Business Asset User Profile Access permission."
    else
      reply_text = "Hello! Your message has been logged into our Agent Inbox."
    end

    client.send_message(sender_id, { text: reply_text }, access_token: access_token)
  end

  # Flow 4: Onboarding Notification
  def process_onboarding(client, sender_id, text, access_token)
    reply_text = "Welcome to our Connected Page service! Your page is active and programmatically subscribed to webhooks."
    client.send_message(sender_id, { text: reply_text }, access_token: access_token)
  end
end

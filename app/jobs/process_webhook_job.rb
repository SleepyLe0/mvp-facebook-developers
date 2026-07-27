class ProcessWebhookJob < ApplicationJob
  queue_as :default

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
        when "faq"
          process_faq(client, sender_id, message_text, page_access_token)
        when "orders"
          process_orders(client, sender_id, message_text, page_access_token)
        when "profiles"
          process_profiles(client, sender_id, message_text, page_access_token)
        when "onboarding"
          process_onboarding(client, sender_id, message_text, page_access_token)
        when "instagram"
          process_instagram(client, sender_id, message_text, page_access_token)
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
      reply_text = "Thanks — a support agent will look into this and get back to you shortly (Ticket ##{ticket.id})."
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

  # Flow 5: Instagram DM Auto-Reply
  def process_instagram(client, sender_id, text, access_token)
    if text.downcase.include?("brand")
      reply_text = "Thanks for reaching out! For brand partnerships, please check our media kit or email partnerships@example.com."
    elsif text.downcase.include?("creator")
      reply_text = "Hey Creator! We love collaborating. Submit your portfolio at example.com/creators."
    else
      reply_text = "Welcome to our Instagram Creator & Brand Portal! Please select your inquiry type:"
    end

    quick_replies = [
      { content_type: "text", title: "I'm a Brand", payload: "brand" },
      { content_type: "text", title: "I'm a Creator", payload: "creator" }
    ]

    message_payload = { text: reply_text, quick_replies: quick_replies }
    client.send_instagram_message(sender_id, message_payload, access_token: access_token)
  end
end

module Profiles
  class InboxController < ApplicationController
    before_action :require_user!
    before_action :set_page

    def index
      @conversations = fetch_conversations
      @tickets_by_psid = current_user.support_tickets.index_by(&:psid)
      @active_psid = params[:psid].presence || @conversations.first&.dig(:psid)
      active = @conversations.find { |c| c[:psid] == @active_psid }
      @active_name = active&.dig(:name) || "Customer"
      @active_ticket = @tickets_by_psid[@active_psid]
      # Graph returns newest-first; show oldest-first like a normal chat
      @thread = (active&.dig(:messages) || []).reverse
      # Messaging windows based on the customer's last inbound message:
      #   ≤24h → standard reply, ≤7d → Human Agent tag only, >7d → nothing can be sent.
      last_in = last_inbound_time(@thread)
      @within_window = last_in.present? && last_in > 24.hours.ago
      @within_7d = last_in.present? && last_in > 7.days.ago
    end

    # Polled by the chat view for near-real-time updates — one Graph call powers
    # both the conversation list and the open thread.
    def poll
      convos = fetch_conversations
      tickets = current_user.support_tickets.index_by(&:psid)
      psid = params[:psid].presence
      active = convos.find { |c| c[:psid] == psid }

      render json: {
        conversations: convos.map { |c| { psid: c[:psid], name: c[:name], snippet: c[:snippet], flag: ticket_flag(tickets[c[:psid]]) } },
        messages: (active&.dig(:messages) || []).reverse.map { |m| message_json(m) }
      }
    end

    def reply
      psid = params[:psid]
      body = params[:body].to_s.strip
      human_agent = params[:human_agent] == "1"

      return bounce(psid, alert: "Connect a page before replying.") if @page.nil?
      return bounce(psid, alert: "Message can't be empty.") if body.blank?

      client = MetaGraphClient.new

      if human_agent
        return bounce(psid, alert: "Confirm you are a human agent before using the Human Agent tag.") if params[:human_confirmation] != "1"

        ticket = current_user.support_tickets.find_or_initialize_by(psid: psid)
        if ticket.persisted? && !ticket.human_agent_window_open?
          return bounce(psid, alert: "⏳ The 7-day Human Agent window has expired for this conversation.")
        end

        response = client.send_message(psid, { text: body }, tag: "HUMAN_AGENT", access_token: @page.access_token)
        if response.is_a?(Hash) && response["error"]
          bounce(psid, alert: "Couldn't send: #{response.dig('error', 'message')}")
        else
          ticket.last_message = body if ticket.last_message.blank?
          ticket.status ||= "open"
          ticket.handled_by_human = true
          ticket.human_agent_notes = "#{current_user.display_name}: '#{body}'"
          ticket.save!
          bounce(psid, notice: "✅ Sent with the Human Agent tag.")
        end
      else
        response = client.send_message(psid, { text: body }, access_token: @page.access_token)
        if response.is_a?(Hash) && response["error"]
          bounce(psid, alert: "Couldn't send: #{response.dig('error', 'message')}")
        else
          bounce(psid)
        end
      end
    end

    # Take over (pause the bot) / resume the bot for a conversation (by psid).
    def toggle_bot
      psid = params[:psid]
      ticket = current_user.support_tickets.find_or_initialize_by(psid: psid)
      ticket.status ||= "open"
      ticket.handled_by_human = !ticket.handled_by_human
      ticket.save!
      flash[:notice] = ticket.handled_by_human ? "You’ve taken over — the bot is paused for this conversation." : "Bot resumed for this conversation."
      redirect_to profiles_inbox_path(psid: psid)
    end

    private

    def bounce(psid, notice: nil, alert: nil)
      flash[:notice] = notice if notice
      flash[:alert] = alert if alert
      redirect_to profiles_inbox_path(psid: psid)
    end

    # ponytail: MVP has one connected page; pick per-conversation page if this goes multi-page
    def set_page
      @page = current_user.connected_pages.first
    end

    def ticket_flag(ticket)
      return nil if ticket.nil?
      ticket.handled_by_human ? "handling" : "needs_human"
    end

    # Time of the customer's most recent inbound message (nil if none/unknown).
    def last_inbound_time(thread)
      return nil if @page.nil? || thread.blank?
      last_inbound = thread.reverse.find { |m| m.dig("from", "id").to_s != @page.page_id.to_s }
      time = last_inbound && last_inbound["created_time"]
      return nil if time.blank?
      Time.parse(time)
    rescue ArgumentError
      nil
    end

    def fetch_conversations
      return [] if @page.nil?

      client = MetaGraphClient.new
      raw = client.get_page_conversations(@page.page_id, access_token: @page.access_token)

      (raw["data"] || []).filter_map do |thread|
        parts = thread.dig("participants", "data") || []
        customer = parts.find { |p| p["id"].to_s != @page.page_id.to_s } || parts.first
        next unless customer

        msgs = thread.dig("messages", "data") || []
        {
          psid: customer["id"],
          name: customer["name"] || "Customer",
          snippet: msgs.first&.dig("message"),
          updated_time: thread["updated_time"],
          messages: msgs
        }
      end
    end

    def message_json(m)
      {
        id: m["id"],
        text: m["message"],
        outgoing: m.dig("from", "id").to_s == @page&.page_id.to_s,
        name: m.dig("from", "name"),
        time: helpers.format_chat_time(m["created_time"])
      }
    end
  end
end

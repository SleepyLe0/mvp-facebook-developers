module Profiles
  class InboxController < ApplicationController
    before_action :require_user!
    before_action :set_page

    def index
      @conversations = fetch_conversations
      @active_psid = params[:psid].presence || @conversations.first&.dig(:psid)
      active = @conversations.find { |c| c[:psid] == @active_psid }
      @active_name = active&.dig(:name) || "Customer"
      # Graph returns newest-first; show oldest-first like a normal chat
      @thread = (active&.dig(:messages) || []).reverse
    end

    # Polled by the chat view for near-real-time updates — one Graph call powers
    # both the conversation list and the open thread.
    # ponytail: 4s polling. Swap for Action Cable + webhook broadcast for instant push.
    def poll
      convos = fetch_conversations
      psid = params[:psid].presence
      active = convos.find { |c| c[:psid] == psid }

      render json: {
        conversations: convos.map { |c| { psid: c[:psid], name: c[:name], snippet: c[:snippet] } },
        messages: (active&.dig(:messages) || []).reverse.map { |m| message_json(m) }
      }
    end

    def reply
      psid = params[:psid]
      body = params[:body].to_s.strip

      if @page.nil?
        flash[:alert] = "Connect a page before replying."
      elsif body.blank?
        flash[:alert] = "Message can't be empty."
      else
        client = MetaGraphClient.new
        response = client.send_message(psid, { text: body }, access_token: @page.access_token)
        if response.is_a?(Hash) && response["error"]
          flash[:alert] = "Couldn't send: #{response.dig('error', 'message')}"
        end
      end

      redirect_to profiles_inbox_path(psid: psid)
    end

    private

    # ponytail: MVP has one connected page; pick per-conversation page if this goes multi-page
    def set_page
      @page = current_user.connected_pages.first
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

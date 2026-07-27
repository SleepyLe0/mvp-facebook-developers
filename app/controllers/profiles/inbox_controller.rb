module Profiles
  class InboxController < ApplicationController
    before_action :require_user!
    before_action :set_page

    def index
      @conversations = []
      return if @page.nil?

      client = MetaGraphClient.new
      raw = client.get_page_conversations(@page.page_id, access_token: @page.access_token)

      (raw["data"] || []).each do |thread|
        parts = thread.dig("participants", "data") || []
        customer = parts.find { |p| p["id"].to_s != @page.page_id.to_s } || parts.first
        next unless customer

        msgs = thread.dig("messages", "data") || []
        @conversations << {
          psid: customer["id"],
          name: customer["name"] || "Customer",
          snippet: msgs.first&.dig("message"),
          updated_time: thread["updated_time"],
          messages: msgs
        }
      end

      # Auto-open the requested (or most recent) conversation
      @active_psid = params[:psid].presence || @conversations.first&.dig(:psid)
      active = @conversations.find { |c| c[:psid] == @active_psid }
      @active_name = active&.dig(:name) || "Customer"
      # Graph returns newest-first; show oldest-first like a normal chat
      @thread = if active
        (active[:messages] || []).reverse
      elsif @active_psid
        client.get_conversation_messages(@page.page_id, @active_psid, access_token: @page.access_token).reverse
      else
        []
      end
    end

    # Polled by the chat view for near-real-time updates.
    # ponytail: 4s polling of Graph. Swap for Action Cable + webhook broadcast if you need instant push.
    def messages
      thread = []
      if @page && params[:psid].present?
        client = MetaGraphClient.new
        thread = client.get_conversation_messages(@page.page_id, params[:psid], access_token: @page.access_token).reverse
      end

      render json: {
        messages: thread.map { |m|
          {
            id: m["id"],
            text: m["message"],
            outgoing: m.dig("from", "id").to_s == @page&.page_id.to_s,
            name: m.dig("from", "name"),
            time: m["created_time"]
          }
        }
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
  end
end

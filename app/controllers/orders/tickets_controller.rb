module Orders
  class TicketsController < ApplicationController
    before_action :require_user!

    def index
      @tickets = SupportTicket.recent
      @page = current_user.connected_pages.first
      @threads = {} # psid => oldest-first messages

      if @page
        # ponytail: one Graph call for all threads; paginate if the queue gets large
        client = MetaGraphClient.new
        raw = client.get_page_conversations(@page.page_id, access_token: @page.access_token)
        (raw["data"] || []).each do |thread|
          parts = thread.dig("participants", "data") || []
          customer = parts.find { |p| p["id"].to_s != @page.page_id.to_s }
          next unless customer
          @threads[customer["id"]] = (thread.dig("messages", "data") || []).reverse
        end
      end
    end

    def reply
      ticket = SupportTicket.find(params[:id])
      reply_text = params[:reply_text]
      category = params[:category]
      confirmation = params[:human_confirmation]

      if confirmation != "1"
        flash[:alert] = "⚠️ Human Operator Verification Required: You must check the human confirmation box before issuing a message using the HUMAN_AGENT tag."
        return redirect_to orders_tickets_path
      end

      if reply_text.blank?
        flash[:alert] = "Reply text cannot be blank."
        return redirect_to orders_tickets_path
      end

      unless ticket.human_agent_window_open?
        flash[:alert] = "⏳ The 7-day Human Agent window has expired. The customer must message again before you can reply."
        return redirect_to orders_tickets_path
      end

      client = MetaGraphClient.new
      # ponytail: MVP has one connected page; scope by ticket.page_id if this goes multi-page
      page = current_user.connected_pages.first
      # Send message using HUMAN_AGENT message tag for outside 24-hour window delivery
      response = client.send_message(ticket.psid, { text: reply_text }, tag: "HUMAN_AGENT", access_token: page&.access_token)

      if response.is_a?(Hash) && response["error"]
        # Nothing delivered — don't pause the bot or record a misleading note.
        flash[:alert] = "Couldn't send: #{response.dig('error', 'message')}"
      else
        # Successful human reply auto-takes-over: the bot goes quiet here.
        ticket.update!(
          handled_by_human: true,
          human_agent_notes: "#{current_user.try(:display_name) || 'Agent'} [#{category}]: '#{reply_text}'"
        )
        flash[:notice] = "✅ Your reply was sent to the customer."
      end
      redirect_to orders_tickets_path
    end

    # Manual bot pause/resume (UChat-style takeover toggle)
    def toggle_bot
      ticket = SupportTicket.find(params[:id])
      ticket.update!(handled_by_human: !ticket.handled_by_human)
      flash[:notice] = ticket.handled_by_human ? "You’ve taken over — the bot is paused for this conversation." : "Bot resumed for this conversation."
      redirect_to orders_tickets_path
    end
  end
end

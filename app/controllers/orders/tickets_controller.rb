module Orders
  class TicketsController < ApplicationController
    before_action :require_user!

    def index
      @tickets = SupportTicket.recent
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
      page = ConnectedPage.first
      # Send message using HUMAN_AGENT message tag for outside 24-hour window delivery
      response = client.send_message(ticket.psid, { text: reply_text }, tag: "HUMAN_AGENT", access_token: page&.access_token)

      ticket.update!(
        status: "resolved",
        human_agent_notes: "Human Operator Reply [Category: #{category}]: '#{reply_text}' (Meta API Status: #{response})"
      )

      flash[:notice] = "✅ Your reply was sent to the customer."
      redirect_to orders_tickets_path
    end
  end
end

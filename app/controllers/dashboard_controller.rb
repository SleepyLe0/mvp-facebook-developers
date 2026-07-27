class DashboardController < ApplicationController
  def index
    @user_pages = logged_in? ? current_user.connected_pages : ConnectedPage.all
    @faq_count = FaqEntry.count
    @order_count = Order.count
    @ticket_count = SupportTicket.count
    @profile_count = UserProfile.count
    @connected_page_count = ConnectedPage.count
    @recent_logs = WebhookLog.order(created_at: :desc).limit(10)
  end
end

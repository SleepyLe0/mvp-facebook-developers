class DashboardController < ApplicationController
  before_action :require_user!

  def index
    @user_pages = current_user.connected_pages
    @connected_page_count = @user_pages.count
    # ponytail: tickets/profiles/logs have no owner column yet, so these stay global.
    # Add page/user ownership if this goes real multi-tenant.
    @faq_count = FaqEntry.count
    @order_count = Order.count
    @ticket_count = SupportTicket.count
    @profile_count = UserProfile.count
    @recent_logs = WebhookLog.order(created_at: :desc).limit(10)
  end
end

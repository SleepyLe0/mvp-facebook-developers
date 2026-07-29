class DashboardController < ApplicationController
  def index
    # Logged-out visitors (and link scrapers) get the sign-in page at the root
    # with a 200 + OG tags, instead of a 302 redirect that hides the tags.
    return render "sessions/new" unless logged_in?

    @user_pages = current_user.connected_pages
    @connected_page_count = @user_pages.count
    # ponytail: tickets/profiles/logs have no owner column yet, so these stay global.
    # Add page/user ownership if this goes real multi-tenant.
    @faq_count = current_user.faq_entries.count
    @order_count = Order.count
    @ticket_count = SupportTicket.count
    @profile_count = UserProfile.count
    @recent_logs = current_user.webhook_logs.order(created_at: :desc).limit(10)
  end
end

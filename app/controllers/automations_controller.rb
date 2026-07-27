class AutomationsController < ApplicationController
  before_action :require_user!

  def index
    @faqs = FaqEntry.all
    @all_pages = current_user.connected_pages
    @ig_pages = @all_pages.where.not(instagram_business_account_id: [nil, ""])
  end
end

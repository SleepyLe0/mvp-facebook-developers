class AutomationsController < ApplicationController
  def index
    @faqs = FaqEntry.all
    @ig_pages = ConnectedPage.where.not(instagram_business_account_id: [nil, ""])
    @all_pages = ConnectedPage.all
  end
end

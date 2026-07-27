class AutomationsController < ApplicationController
  before_action :require_user!

  def index
    @faqs = FaqEntry.order(created_at: :desc)
    @all_pages = current_user.connected_pages
    @ig_pages = @all_pages.where.not(instagram_business_account_id: [nil, ""])
  end

  def create_rule
    faq = FaqEntry.new(question: params[:question], keywords: params[:keywords], answer: params[:answer])
    if faq.save
      flash[:notice] = "Auto-reply rule added."
    else
      flash[:alert] = faq.errors.full_messages.to_sentence
    end
    redirect_to automations_path
  end

  def destroy_rule
    FaqEntry.find_by(id: params[:id])&.destroy
    flash[:notice] = "Rule removed."
    redirect_to automations_path
  end
end

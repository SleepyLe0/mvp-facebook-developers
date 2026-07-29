class AutomationsController < ApplicationController
  before_action :require_user!

  def index
    @faqs = current_user.faq_entries.order(created_at: :desc)
  end

  def create_rule
    faq = current_user.faq_entries.new(question: params[:question], keywords: params[:keywords], answer: params[:answer])
    if faq.save
      flash[:notice] = "Auto-reply rule added."
    else
      flash[:alert] = faq.errors.full_messages.to_sentence
    end
    redirect_to automations_path
  end

  def destroy_rule
    current_user.faq_entries.find_by(id: params[:id])&.destroy
    flash[:notice] = "Rule removed."
    redirect_to automations_path
  end
end

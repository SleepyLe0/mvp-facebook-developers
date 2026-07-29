class WebhookLogsController < ApplicationController
  before_action :require_user!

  def index
    @logs = current_user.webhook_logs.order(created_at: :desc).limit(50)
  end

  def clear
    current_user.webhook_logs.destroy_all
    flash[:notice] = "Activity cleared."
    redirect_to webhook_logs_path
  end
end

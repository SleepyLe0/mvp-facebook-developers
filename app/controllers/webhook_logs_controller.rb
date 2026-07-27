class WebhookLogsController < ApplicationController
  def index
    @logs = WebhookLog.order(created_at: :desc).limit(50)
  end

  def clear
    WebhookLog.destroy_all
    flash[:notice] = "Webhook logs cleared."
    redirect_to webhook_logs_path
  end
end

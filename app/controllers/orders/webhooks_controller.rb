module Orders
  class WebhooksController < ApplicationController
    include WebhookVerifiable
    skip_before_action :verify_authenticity_token

    def create
      payload = JSON.parse(request.raw_post)
      ProcessWebhookJob.perform_later("orders", payload)
      render json: { status: "received" }, status: :ok
    rescue JSON::ParserError
      render json: { error: "Invalid JSON" }, status: :bad_request
    end
  end
end

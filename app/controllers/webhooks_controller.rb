# Unified Messenger webhook — one callback URL that runs the full support flow:
# FAQ auto-reply → order lookup → human fallback. Point the Facebook Messenger
# callback URL here (/webhook) so every capability works at once.
class WebhooksController < ApplicationController
  include WebhookVerifiable
  skip_before_action :verify_authenticity_token

  def create
    payload = JSON.parse(request.raw_post)
    ProcessWebhookJob.perform_later("unified", payload)
    render json: { status: "received" }, status: :ok
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end
end

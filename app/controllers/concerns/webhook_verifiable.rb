module WebhookVerifiable
  extend ActiveSupport::Concern

  included do
    before_action :verify_signature!, only: [:create]
  end

  # GET /webhook
  def verify
    mode = params["hub.mode"]
    token = params["hub.verify_token"]
    challenge = params["hub.challenge"]

    verify_token = ENV.fetch("FB_VERIFY_TOKEN", "demo_webhook_verify_token")

    if mode == "subscribe" && token == verify_token
      Rails.logger.info "[WebhookVerifiable] Webhook verified successfully."
      render plain: challenge, status: :ok
    else
      Rails.logger.warn "[WebhookVerifiable] Webhook verification failed. Received token: #{token.inspect}"
      render plain: "Verification failed", status: :forbidden
    end
  end

  private

  # POST /webhook signature check
  def verify_signature!
    signature = request.headers["X-Hub-Signature-256"]
    app_secret = ENV.fetch("FB_APP_SECRET", "demo_fb_app_secret")

    # In dev/demo mode, if signature is absent and secret is default, log warning but allow mock testing if needed
    if signature.blank?
      Rails.logger.warn "[WebhookVerifiable] Missing X-Hub-Signature-256 header."
      WebhookLog.create!(
        event_type: "signature_warning",
        payload: request.raw_post,
        status: "missing_signature",
        error_message: "Missing X-Hub-Signature-256 header"
      )
      return render json: { error: "Missing signature" }, status: :unauthorized
    end

    raw_post = request.raw_post
    expected_signature = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", app_secret, raw_post)

    unless ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
      Rails.logger.error "[WebhookVerifiable] Signature mismatch. Expected: #{expected_signature}, Got: #{signature}"
      WebhookLog.create!(
        event_type: "signature_error",
        payload: raw_post,
        status: "invalid_signature",
        error_message: "Signature mismatch"
      )
      render json: { error: "Invalid payload signature" }, status: :unauthorized
    end
  end
end

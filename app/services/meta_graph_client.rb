require "faraday"
require "json"

class MetaGraphClient
  BASE_URL = "https://graph.facebook.com".freeze

  attr_reader :version, :app_id, :app_secret, :default_page_token

  def initialize(
    version: ENV.fetch("GRAPH_API_VERSION", "v20.0"),
    app_id: ENV["FB_APP_ID"],
    app_secret: ENV["FB_APP_SECRET"],
    default_page_token: ENV["FB_PAGE_ACCESS_TOKEN"]
  )
    @version = version
    @app_id = app_id
    @app_secret = app_secret
    @default_page_token = default_page_token
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  # Boss Requirement #2: Fetch Chat History (Conversations API)
  def get_page_conversations(page_id = nil, access_token: nil)
    token = access_token.presence || default_page_token
    target_id = page_id.presence || "me"
    endpoint = "/#{version}/#{target_id}/conversations"

    response = @conn.get(endpoint) do |req|
      req.params["fields"] = "id,updated_time,participants,messages{id,message,from,created_time}"
      req.params["access_token"] = token
    end

    log_response("get_page_conversations", response)
    response.body
  end

  # Fetch a single customer's message thread with the page (for the chat view).
  # Returns the messages array (Graph returns newest-first).
  def get_conversation_messages(page_id, psid, access_token: nil)
    token = access_token.presence || default_page_token
    endpoint = "/#{version}/#{page_id}/conversations"

    response = @conn.get(endpoint) do |req|
      req.params["user_id"] = psid
      req.params["fields"] = "messages{id,message,from,created_time}"
      req.params["access_token"] = token
    end

    log_response("get_conversation_messages", response)
    (response.body.dig("data", 0, "messages", "data") || [])
  end

  # Fetch authenticated Facebook User profile (id, name)
  def get_me(user_access_token)
    endpoint = "/#{version}/me"

    response = @conn.get(endpoint) do |req|
      req.params["fields"] = "id,name"
      req.params["access_token"] = user_access_token
    end

    log_response("get_me", response)
    response.body
  end

  # OAuth Step 1: Exchange authorization code for user access token
  def exchange_code_for_token(code, redirect_uri)
    endpoint = "/#{version}/oauth/access_token"

    response = @conn.get(endpoint) do |req|
      req.params["client_id"] = app_id
      req.params["client_secret"] = app_secret
      req.params["redirect_uri"] = redirect_uri
      req.params["code"] = code
    end

    log_response("exchange_code_for_token", response)
    response.body
  end

  # OAuth Step 2: Exchange short-lived user token for 60-day long-lived token
  def get_long_lived_token(short_lived_token)
    endpoint = "/#{version}/oauth/access_token"

    response = @conn.get(endpoint) do |req|
      req.params["grant_type"] = "fb_exchange_token"
      req.params["client_id"] = app_id
      req.params["client_secret"] = app_secret
      req.params["fb_exchange_token"] = short_lived_token
    end

    log_response("get_long_lived_token", response)
    response.body
  end

  # Flow 1 & 2: Send Facebook Page Messenger message
  def send_message(recipient_id, message_payload, tag: nil, access_token: nil)
    token = access_token.presence || default_page_token
    endpoint = "/#{version}/me/messages"

    body = {
      recipient: { id: recipient_id },
      message: message_payload
    }

    if tag.present?
      body[:messaging_type] = "MESSAGE_TAG"
      body[:tag] = tag
    else
      body[:messaging_type] = "RESPONSE"
    end

    response = @conn.post(endpoint) do |req|
      req.params["access_token"] = token
      req.headers["Content-Type"] = "application/json"
      req.body = body
    end

    log_response("send_message", response)
    response.body
  end

  # Flow 3: Fetch User Profile using Business Asset User Profile Access permission
  def get_user_profile(psid, access_token: nil)
    token = access_token.presence || default_page_token
    endpoint = "/#{version}/#{psid}"

    response = @conn.get(endpoint) do |req|
      req.params["fields"] = "first_name,last_name,profile_pic,locale"
      req.params["access_token"] = token
    end

    log_response("get_user_profile", response)
    response.body
  end

  # Flow 4: List accounts for Facebook Login for Business (OAuth)
  def get_user_pages(user_access_token)
    endpoint = "/#{version}/me/accounts"

    response = @conn.get(endpoint) do |req|
      req.params["access_token"] = user_access_token
      req.params["fields"] = "id,name,access_token,category,tasks"
    end

    log_response("get_user_pages", response)
    response.body
  end

  # Flow 4: Programmatically subscribe app to Page webhooks
  def subscribe_page_app(page_id, page_access_token)
    endpoint = "/#{version}/#{page_id}/subscribed_apps"

    response = @conn.post(endpoint) do |req|
      req.params["access_token"] = page_access_token
      req.params["subscribed_fields"] = "messages,messaging_postbacks,messaging_optins,message_echoes,messaging_policy_enforcement"
    end

    log_response("subscribe_page_app", response)
    response.body
  end

  # Set the Messenger welcome screen: Get Started button, ice breakers (welcome
  # prompts), and persistent menu. Note: v18+ dropped `greeting`; ice_breakers
  # is its modern replacement.
  def set_messenger_profile(page_access_token)
    endpoint = "/#{version}/me/messenger_profile"

    body = {
      get_started: { payload: "GET_STARTED" },
      ice_breakers: [{
        locale: "default",
        call_to_actions: [
          { question: "What can you do?", payload: "GET_STARTED" },
          { question: "Check an order", payload: "CHECK_ORDER" },
          { question: "Talk to a human", payload: "TALK_TO_HUMAN" }
        ]
      }],
      persistent_menu: [{
        locale: "default",
        composer_input_disabled: false,
        call_to_actions: [
          { type: "postback", title: "Check an order", payload: "CHECK_ORDER" },
          { type: "postback", title: "Talk to a human", payload: "TALK_TO_HUMAN" },
          { type: "postback", title: "Get started", payload: "GET_STARTED" }
        ]
      }]
    }

    response = @conn.post(endpoint) do |req|
      req.params["access_token"] = page_access_token
      req.headers["Content-Type"] = "application/json"
      req.body = body
    end

    log_response("set_messenger_profile", response)
    response.body
  end

  private

  def log_response(action, response)
    if response.success?
      Rails.logger.info "[MetaGraphClient] #{action} SUCCESS: #{response.body}"
    else
      Rails.logger.error "[MetaGraphClient] #{action} ERROR #{response.status}: #{response.body}"
    end
  end
end

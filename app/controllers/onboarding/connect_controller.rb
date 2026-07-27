module Onboarding
  class ConnectController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:subscribe]
    before_action :require_user!

    def index
      @connected_pages = current_user.connected_pages
      @app_id = ENV["FB_APP_ID"]
      @redirect_uri = "#{request.base_url}/onboarding/callback"
      @oauth_url = "https://www.facebook.com/v20.0/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{CGI.escape(@redirect_uri)}&scope=pages_show_list,pages_manage_metadata,business_management,pages_messaging"
    end

    def callback
      code = params[:code]
      user_token = params[:user_access_token].presence || code

      if user_token.blank?
        flash[:alert] = "No authorization code or token provided."
        return redirect_to onboarding_connect_path
      end

      client = MetaGraphClient.new

      # If code is passed from OAuth dialog, exchange code for user access token
      if code.present? && params[:user_access_token].blank?
        redirect_uri = "#{request.base_url}/onboarding/callback"
        token_response = client.exchange_code_for_token(code, redirect_uri)
        user_token = token_response["access_token"] if token_response["access_token"].present?
      end

      if user_token.blank?
        flash[:alert] = "Could not exchange OAuth authorization code for token."
        return redirect_to onboarding_connect_path
      end

      # Exchange for 60-day long-lived user access token
      long_lived_response = client.get_long_lived_token(user_token)
      final_user_token = long_lived_response["access_token"].presence || user_token

      # Save Facebook User Access Token to current user profile
      current_user.update!(facebook_access_token: final_user_token)

      # Fetch manageable Facebook Pages
      pages_response = client.get_user_pages(final_user_token)

      if pages_response["data"].present?
        @pages = pages_response["data"]
        @user_token = final_user_token
      else
        flash[:alert] = "Could not fetch pages: #{pages_response['error']&.dig('message') || 'No pages returned'}"
        redirect_to onboarding_connect_path
      end
    end

    def subscribe
      page_id = params[:page_id]
      page_name = params[:page_name]
      page_access_token = params[:page_access_token]

      client = MetaGraphClient.new
      response = client.subscribe_page_app(page_id, page_access_token)

      if response["success"] || response["result"] == "success"
        ig_account_id = params[:instagram_business_account_id]

        connected_page = ConnectedPage.find_or_initialize_by(page_id: page_id)
        connected_page.update!(
          user: current_user,
          name: page_name,
          access_token: page_access_token,
          instagram_business_account_id: ig_account_id,
          subscribed: true
        )

        flash[:notice] = "🎉 Successfully connected Page '#{page_name}' (ID: #{page_id}) to your account and subscribed webhooks!"
      else
        flash[:alert] = "Subscription failed: #{response}"
      end

      redirect_to onboarding_connect_path
    end
  end
end

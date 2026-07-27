class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:callback]

  def new
    @app_id = ENV["FB_APP_ID"]
    @redirect_uri = "#{request.base_url}/auth/facebook/callback"
    @oauth_url = "https://www.facebook.com/v20.0/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{CGI.escape(@redirect_uri)}&scope=public_profile,pages_show_list,pages_manage_metadata,business_management,pages_messaging"
  end

  def facebook
    app_id = ENV["FB_APP_ID"]
    redirect_uri = "#{request.base_url}/auth/facebook/callback"
    oauth_url = "https://www.facebook.com/v20.0/dialog/oauth?client_id=#{app_id}&redirect_uri=#{CGI.escape(redirect_uri)}&scope=public_profile,pages_show_list,pages_manage_metadata,business_management,pages_messaging"
    redirect_to oauth_url, allow_other_host: true
  end

  def callback
    code = params[:code]
    user_token = params[:user_access_token].presence || code

    if user_token.blank?
      flash[:alert] = "Authentication failed: No authorization code or access token received from Facebook."
      return redirect_to login_path
    end

    client = MetaGraphClient.new

    # Exchange code for User Access Token if OAuth code is provided
    if code.present? && params[:user_access_token].blank?
      redirect_uri = "#{request.base_url}/auth/facebook/callback"
      token_response = client.exchange_code_for_token(code, redirect_uri)
      user_token = token_response["access_token"] if token_response["access_token"].present?
    end

    if user_token.blank?
      flash[:alert] = "Could not exchange authorization code for Facebook Access Token."
      return redirect_to login_path
    end

    # Upgrade to 60-day Long-Lived Token
    long_lived_response = client.get_long_lived_token(user_token)
    final_token = long_lived_response["access_token"].presence || user_token

    # Fetch User Identity via GET /me
    me_data = client.get_me(final_token)
    fb_uid = me_data["id"] || "demo_fb_uid_#{Time.now.to_i}"
    user_name = me_data["name"] || "Facebook User"
    user_email = me_data["email"].presence || "user_#{fb_uid}@facebook.com"

    # Find or Create User by Facebook UID
    user = User.find_or_initialize_by(facebook_uid: fb_uid)
    user.update!(
      name: user_name,
      email: user_email,
      facebook_access_token: final_token
    )

    session[:user_id] = user.id
    flash[:notice] = "Successfully authenticated as #{user.display_name} via Facebook Login!"

    # Redirect to Page Onboarding
    redirect_to onboarding_connect_path
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = "Signed out of Facebook session."
    redirect_to root_path
  end
end

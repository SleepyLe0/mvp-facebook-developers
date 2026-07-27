module Profiles
  class InboxController < ApplicationController
    before_action :require_user!
    before_action :set_page

    def index
      @profiles = UserProfile.order(updated_at: :desc)
      @active_psid = params[:psid].presence

      if @active_psid && @page
        @active_profile = UserProfile.find_by(psid: @active_psid)
        client = MetaGraphClient.new
        # Graph returns newest-first; show oldest-first like a normal chat
        @thread = client.get_conversation_messages(@page.page_id, @active_psid, access_token: @page.access_token).reverse
      end
    end

    def reply
      psid = params[:psid]
      body = params[:body].to_s.strip

      if @page.nil?
        flash[:alert] = "Connect a page before replying."
      elsif body.blank?
        flash[:alert] = "Message can't be empty."
      else
        client = MetaGraphClient.new
        response = client.send_message(psid, { text: body }, access_token: @page.access_token)
        if response.is_a?(Hash) && response["error"]
          flash[:alert] = "Couldn't send: #{response.dig('error', 'message')}"
        end
      end

      redirect_to profiles_inbox_path(psid: psid)
    end

    private

    # ponytail: MVP has one connected page; pick per-conversation page if this goes multi-page
    def set_page
      @page = current_user.connected_pages.first
      @connected_pages = current_user.connected_pages
    end
  end
end

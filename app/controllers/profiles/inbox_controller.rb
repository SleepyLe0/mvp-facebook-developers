module Profiles
  class InboxController < ApplicationController
    before_action :require_user!

    def index
      @profiles = UserProfile.order(updated_at: :desc)
      @connected_pages = current_user.connected_pages

      # Boss Requirement #2: If user clicks "Fetch Meta Chat History"
      if params[:page_id].present?
        page = ConnectedPage.find_by(page_id: params[:page_id])
        if page
          client = MetaGraphClient.new
          @conversations_response = client.get_page_conversations(page.page_id, access_token: page.access_token)
          flash.now[:notice] = "Fetched historical conversations from Meta Graph API for Page: #{page.name}!"
        end
      end
    end
  end
end

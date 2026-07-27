module Instagram
  class AccountsController < ApplicationController
    def index
      # Instagram management now lives on the Automations page
      redirect_to automations_path
    end

    def fetch_ig_account
      page_id = params[:page_id]
      page = ConnectedPage.find_by(page_id: page_id)

      unless page
        flash[:alert] = "Page not found in connected pages."
        return redirect_to instagram_accounts_path
      end

      client = MetaGraphClient.new
      response = client.get_instagram_account(page.page_id, page.access_token)

      ig_account_id = response.dig("instagram_business_account", "id")

      if ig_account_id.present?
        page.update!(instagram_business_account_id: ig_account_id)
        flash[:notice] = "Linked Instagram Professional Account ID: #{ig_account_id} to Page: #{page.name}!"
      else
        flash[:alert] = "No Instagram Business Account linked to this Facebook Page."
      end

      redirect_to automations_path
    end
  end
end

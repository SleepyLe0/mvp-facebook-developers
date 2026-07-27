Rails.application.routes.draw do
  root "dashboard#index"

  # Facebook SSO Authentication
  get "login", to: "sessions#new", as: :login
  get "auth/facebook", to: "sessions#facebook", as: :facebook_login
  get "auth/facebook/callback", to: "sessions#callback"
  post "auth/facebook/callback", to: "sessions#callback"
  delete "logout", to: "sessions#destroy", as: :logout

  resources :webhook_logs, only: [:index] do
    collection do
      delete :clear
    end
  end

  # Automations: view and manage auto-reply rules
  get "automations", to: "automations#index"
  post "automations/rules", to: "automations#create_rule", as: :automation_rules
  delete "automations/rules/:id", to: "automations#destroy_rule", as: :automation_rule

  # Flow 1: Page Auto-Responder / FAQ Bot
  namespace :faq do
    get "webhook", to: "webhooks#verify"
    post "webhook", to: "webhooks#create"
  end

  # Flow 2: Order/Inquiry Status Bot with Human Handoff
  namespace :orders do
    get "webhook", to: "webhooks#verify"
    post "webhook", to: "webhooks#create"
    get "tickets", to: "tickets#index"
    post "tickets/:id/reply", to: "tickets#reply", as: :reply_ticket
    post "tickets/:id/toggle_bot", to: "tickets#toggle_bot", as: :toggle_bot_ticket
  end

  # Flow 3: Page Profile Lookup for Support Agents
  namespace :profiles do
    get "webhook", to: "webhooks#verify"
    post "webhook", to: "webhooks#create"
    get "inbox", to: "inbox#index"
    get "inbox/poll", to: "inbox#poll", as: :inbox_poll
    post "inbox/reply", to: "inbox#reply", as: :inbox_reply
  end

  # Flow 4: Page Connect / Onboarding Flow
  namespace :onboarding do
    get "webhook", to: "webhooks#verify"
    post "webhook", to: "webhooks#create"
    get "connect", to: "connect#index"
    get "callback", to: "connect#callback"
    post "subscribe", to: "connect#subscribe"
  end

  # Flow 5: Instagram DM Auto-Reply for Creator/Brand Inquiries
  namespace :instagram do
    get "webhook", to: "webhooks#verify"
    post "webhook", to: "webhooks#create"
    get "accounts", to: "accounts#index"
    post "fetch_ig_account", to: "accounts#fetch_ig_account"
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end

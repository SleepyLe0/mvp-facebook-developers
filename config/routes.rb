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

  # Unified Messenger webhook — point the Facebook callback URL here.
  # Runs FAQ → order lookup → human fallback in one endpoint.
  get "webhook", to: "webhooks#verify"
  post "webhook", to: "webhooks#create"

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
    post "inbox/toggle_bot", to: "inbox#toggle_bot", as: :inbox_toggle_bot
  end

  # Flow 4: Page Connect / Onboarding Flow
  namespace :onboarding do
    get "webhook", to: "webhooks#verify"
    post "webhook", to: "webhooks#create"
    get "connect", to: "connect#index"
    get "callback", to: "connect#callback"
    post "subscribe", to: "connect#subscribe"
  end

  # Public legal pages (no login — reviewers must reach these)
  get "privacy", to: "pages#privacy"
  get "data-deletion", to: "pages#data_deletion"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end

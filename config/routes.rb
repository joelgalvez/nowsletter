Rails.application.routes.draw do
  get "robots.txt", to: ->(env) {
    body = ENV["NOINDEX"] == "true" ? "User-agent: *\nDisallow: /\n" : "User-agent: *\nAllow: /\n"
    [ 200, { "Content-Type" => "text/plain" }, [ body ] ]
  }

  resources :settings do
    collection do
      post :test_system_notification
    end
  end
  resources :available_models, only: [ :index ]
  resources :email_templates
  resources :prompts
  resources :llm_jobs
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?


  resources :subscribers, only: [ :index, :create, :destroy ]
  # get "subscribe", to: "subscribers#subscribe", as: "subscribe"
  get "subscribers/confirm/:token", to: "subscribers#confirm", as: "confirm_subscriber"
  resources :pages
  resources :blacklists do
    collection do
      post :toggle
    end
  end
  resources :logs
  resource :session
  resources :passwords, param: :token
  resources :posts

  resources :lists
  resources :cities do
    collection do
      post :create_with_country
    end
  end
  resources :countries
  resources :messages

  # API routes
  namespace :api do
    post "login", to: "sessions#create"
    get "current_user", to: "sessions#current"
    resources :llm_jobs, only: [ :index, :update ] do
      post :claim, on: :collection
    end
    resources :available_models, only: [ :create ]
  end

  resources :tags do
    collection do
      get :search
    end
  end
  resources :senders
  resources :users
  resources :venues do
    collection do
      get :search
    end

    member do
      delete :delete_events_and_letters
    end
  end

  resources :events do
    member do
      patch :toggle_status
      patch :unpublish
      patch :remove_image
      patch :blacklist_image
    end
  end
  resources :letters do
    member do
      patch :update_status
      patch :allow_this_and_future
      patch :allow_future_only
      get :body
    end
  end


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "interesting/script", to: "interesting#script"
  post "interesting/event", to: "interesting#event"

  get "up" => "rails/health#show", as: :rails_health_check

  # Status check for pending letters
  get "status" => "llm_jobs#status", as: :status




  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  #



  get "dashboard", to: "dashboard#index", as: "dashboard"
  get "dashboard/tags/search", to: "dashboard#search_tags", as: "search_dashboard_tags"
  get "dashboard/events/:event_id/edit", to: "dashboard#edit_event", as: "edit_dashboard_event"
  get "dashboard/:letter_id/events/new", to: "dashboard#new_event", as: "new_dashboard_event"
  get "dashboard/:letter_id", to: "dashboard#letter", as: "dashboard_letter"
  patch "dashboard/:letter_id/publish_all", to: "dashboard#publish_all", as: "publish_all_dashboard_letter"
  patch "dashboard/:letter_id/unpublish_all", to: "dashboard#unpublish_all", as: "unpublish_all_dashboard_letter"
  delete "dashboard/:letter_id/delete_all_events", to: "dashboard#delete_all_events", as: "delete_all_events_dashboard_letter"
  post "dashboard/:letter_id/send_test_email", to: "dashboard#send_test_email", as: "send_test_email_dashboard_letter"
  post "dashboard/:letter_id/send_custom_template", to: "dashboard#send_custom_template", as: "send_custom_template_dashboard_letter"

  post "global_settings/toggle", to: "global_settings#toggle", as: "toggle_global_setting"

  get "opt_out", to: "opt_outs#show", as: "opt_out"
  patch "opt_out", to: "opt_outs#update"

  get "import", to: "imports#index", as: "import"
  post "import", to: "imports#preview", as: "import_preview"
  post "import/confirm", to: "imports#create", as: "import_confirm"

  get "overview/letter/:id", to: "overview#letter", as: "overview_letter"
  get "overview/event/:event_id", to: "overview#event", as: "overview_event"

  get "subscribe-not-really-public", to: "subscribers#subscribe", as: "subscribe_not_really_public"
  # get "not/:list_title", to: "overview#list", as: "overview_list"


  # Fallback route for page slugs - must be last
  # get "*slug", to: "pages#show_by_slug", as: :page_slug
  get ":slug", to: "view_page#show", as: "view_page_show_slug"

  # Defines the root path route ("/")
  root "overview#list"
end

Rails.application.routes.draw do

  mount Ckeditor::Engine => '/ckeditor'
  devise_for :users, :controllers => { registrations: "registrations", omniauth_callbacks: 'omniauth_callbacks' } do
    get "logout", to: "devise/sessions#destroy"
  end
  
  namespace :admin do
    root to: 'base#home'
    get :reports, to: 'base#reports'
    resources :activities
    resources :credits do
      member do
        get :resubmit
        get :respend
      end
    end
    resources :emails do
      member do
        get :send_to_list
        get :send_test
        post :send_test_address
      end
    end
    resources :ethtransactions
    resources :instances_users
    resources :experiments do
      resources :instances

    end
    resources :pages
    resources :posts
    resources :proposals
    resources :proposalstatuses
    resources :roombookings
    resources :users
  end
  
  resources :opensessions
  resources :experiments do
    resources :comments

    resources :users do
      resources :notifications
    end

    collection do
      get :tree
      get :radial
      get :hierarchy
      get :calendar
      get :archive
    end
    resources :instances, path: '' do
      resources :registrations, controller: :experiment_registrations
      resources :userphotos, controller: :viewpoints
      member do
        post :rsvp
        post :register
        post :cancel_rsvp
        post :cancel_registration
        get :stats
        resources :users do
          get :make_organiser
          get :remove_organiser
        end
      end
    end

  end
  
  resources :activities
  resources :authentications do
    collection do
      post :add_provider
    end
  end
  
  
  resources :onetimers do
    collection do
      post :link_tag
    end
  end
  
  resources :comments
  
  resources :pages
  resources :posts
  
  resources :proposals do
    resources :comments
    resources :pledges
    resources :users do
      resources :notifications
    end
    
    collection do
      get :archived
      get :active
    end
  end
  
  
  resources :roombookings do
    collection do
      get :calendar
    end
  end
  
  resources :users do
    collection do
      get :mentions
    end
    member do
      get :buy_photoslot
    end
    resources :activities
    resources :transfers  do
      collection do
        get :send_temps
        post :post_temps
      end
    end
    resources :accounts do 
      member do
        get :set_as_primary
      end
    end
        
  end
  get '/events/:id', to: 'experiments#redirect_event'
  get '/category/:id', to: "postcategories#show"
  get '/announcements/:id' => 'emails#show'
  match '/link_temporary' => 'onetimers#link', via: :get
  match '/admin/:id/resubmit' => 'admin/base#resubmit', via: :post
  match '/admin/:id/respend' => 'admin/base#respend', via: :get
  match '/admin/:id/retransfer' => 'admin/base#retransfer', via: :get
  match '/users/auth/:provider/callback' => 'authentications#create', :via => :get
  match '/admin/nfcs/:id/toggle' => 'admin/base#toggle_key', via: :get
  match '/admin/nfcs/:id' => 'admin/base#delete_nfc', via: :delete
  match '/search_proposals' => 'proposals#search', via: :post
  delete '/users/signout' => 'devise/sessions#destroy', :as => :signout
  root to: 'home#index'
end

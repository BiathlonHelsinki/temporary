Rails.application.routes.draw do

  mount Ckeditor::Engine => '/ckeditor'
  devise_for :users, :controllers => { registrations: "registrations", omniauth_callbacks: 'omniauth_callbacks' } do
    get "logout", to: "devise/sessions#destroy"
  end
  
  namespace :admin do
    root to: 'base#home'
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
    resources :users
  end
  
  resources :experiments do
    resources :comments
    collection do
      get :tree
      get :radial
      get :hierarchy
      get :calendar
    end
    resources :instances, path: '' do
      member do
        post :rsvp
        post :cancel_rsvp
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
  
  get '/announcements/:id' => 'emails#show'
  match '/link_temporary' => 'onetimers#link', via: :get
  match '/admin/:id/resubmit' => 'admin/base#resubmit', via: :post
  match '/admin/:id/respend' => 'admin/base#respend', via: :get
  match '/admin/:id/retransfer' => 'admin/base#retransfer', via: :get
  match '/users/auth/:provider/callback' => 'authentications#create', :via => :get
  match '/admin/nfcs/:id/toggle' => 'admin/base#toggle_key', via: :get
  delete '/users/signout' => 'devise/sessions#destroy', :as => :signout
  root to: 'home#index'
end

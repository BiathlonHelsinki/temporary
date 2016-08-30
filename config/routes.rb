Rails.application.routes.draw do
  devise_for :users, :controllers => { omniauth_callbacks: 'omniauth_callbacks' } do
    get "logout", to: "devise/sessions#destroy"
  end
  
  namespace :admin do
    root to: 'base#home'
    resources :credits
    resources :experiments do
      resources :instances
    end
    resources :posts
    resources :proposals
    resources :users
  end
  
  resources :experiments do
    collection do
      get :tree
      get :radial
      get :hierarchy
      get :calendar
    end
    member do
      resources :instances
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
  

  resources :posts
  
  resources :proposals do
    resources :comments
    resources :pledges
  end
  
  
  
  resources :users do
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
  
  get '/experiments/:experiment_id/:id', to: "instances#show"
  match '/link_temporary' => 'onetimers#link', via: :get
  
  match '/users/auth/:provider/callback' => 'authentications#create', :via => :get
  delete '/users/signout' => 'devise/sessions#destroy', :as => :signout
  root to: 'home#index'
end
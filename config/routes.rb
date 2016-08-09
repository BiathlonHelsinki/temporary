Rails.application.routes.draw do
  devise_for :users, :controllers => { omniauth_callbacks: 'omniauth_callbacks' } do
    get "logout", to: "devise/sessions#destroy"
  end
  
  namespace :admin do
    root to: 'base#home'
    resources :experiments
    resources :users
  end
  
  resources :experiments
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
  
  resources :proposals do
    
  end
  
  resources :users do
    resources :activities
  end
  
  match '/link_temporary' => 'onetimers#link', via: :get
  
  match '/users/auth/:provider/callback' => 'authentications#create', :via => :get
  delete '/users/signout' => 'devise/sessions#destroy', :as => :signout
  root to: 'activities#index'
end

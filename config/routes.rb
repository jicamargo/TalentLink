Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  root 'home#index'
  get 'auth/linkedin/callback', to: 'sessions#linkedin_callback'
  get 'auth/linkedin', to: 'sessions#linkedin_auth'
  
end

Rails.application.routes.draw do
  devise_for :users
  root 'home#index'
  get 'auth/linkedin', to: 'sessions#linkedin_auth'
  get 'auth/linkedin/callback', to: 'sessions#linkedin_callback'
  get 'profile', to: 'sessions#profile'
end

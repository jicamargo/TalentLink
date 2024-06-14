Rails.application.routes.draw do
  devise_for :users
  root 'home#index'
  get 'auth/linkedin', to: 'sessions#linkedin_auth'
  get 'auth/linkedin/callback', to: 'sessions#linkedin_callback'
  get 'profile', to: 'sessions#profile'

  # Rutas para consultar posts y estadísticas
  get 'sessions/get_user_posts', to: 'sessions#get_user_posts', as: 'get_user_posts'
  get 'sessions/get_post_analytics', to: 'sessions#get_post_analytics', as: 'get_post_analytics'

end

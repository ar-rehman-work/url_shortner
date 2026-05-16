Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  post '/signup', to: 'auth#signup'
  post '/login', to: 'auth#login'

  root 'short_urls#index'
  post '/shorten', to: 'short_urls#create'
  get '/s/:short_code', to: 'short_urls#redirect_by_short_code'
  get '/:custom_alias', to: 'short_urls#redirect_by_custom_alias'
end

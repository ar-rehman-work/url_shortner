require 'sidekiq/web'

Rails.application.routes.draw do
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(
      username,
      ENV.fetch('SIDEKIQ_USERNAME')
    ) &
    ActiveSupport::SecurityUtils.secure_compare(
      password,
      ENV.fetch('SIDEKIQ_PASSWORD')
    )
  end

  mount Sidekiq::Web => '/sidekiq'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      post '/signup', to: 'auth#signup'
      post '/login', to: 'auth#login'

      resources :short_urls
    end
  end

  get '/s/:short_code', to: 'api/v1/short_urls#redirect_by_short_code'
  get '/a/:custom_alias', to: 'api/v1/short_urls#redirect_by_custom_alias'
end

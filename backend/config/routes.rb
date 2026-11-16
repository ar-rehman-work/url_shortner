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

  scope path: 'api/v1' do
    mount Sidekiq::Web => '/sidekiq'

    post '/signup', to: 'auth#signup'
    post '/login', to: 'auth#login'

    root 'short_urls#index'
    post '/shorten', to: 'short_urls#create'

    get '/up', to: 'rails/health#show', as: :rails_health_check
  end

  # Short URL redirects
  get '/:short_code', to: 'short_urls#redirect', constraints: { short_code: /[a-zA-Z0-9_-]+/ }
end

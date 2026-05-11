class ShortUrlsController < ApplicationController
  include Pagy::Backend

  skip_before_action :authenticate_user!, only: [:redirect]
  before_action :check_long_url, only: [:create]

  def index
    filtered_urls = current_user.short_urls

    if params[:q].present?
      query = "%#{params[:q]}%"

      filtered_urls = filtered_urls.where(
        'long_url ILIKE :q OR short_code ILIKE :q OR custom_alias ILIKE :q',
        q: query
      )
    end

    if ActiveModel::Type::Boolean.new.cast(params[:expired])
      filtered_urls = filtered_urls.where(
        'expires_at IS NOT NULL AND expires_at <= ?',
        Time.current
      )
    end

    limit = params[:limit].to_i
    limit = 10 if limit <= 0
    limit = 50 if limit > 50

    @pagy, short_urls = pagy(filtered_urls.order(created_at: :desc), items: limit)

    render json: { data: short_urls, pagination: pagy_metadata(@pagy) }
  end

  def create
    short_url = ShortUrl.find_or_initialize_by(long_url: short_url_params[:long_url], user_id: current_user.id)
    short_url.expires_at = short_url_params[:expires_at].presence
    short_url.custom_alias = short_url_params[:custom_alias].presence

    if short_url.save
      render json: { short_code: short_url.short_code }, status: :ok
    else
      render json: { errors: short_url.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def redirect
    short_url = ShortUrl.find_by(short_code: params[:short_code]) || ShortUrl.find_by(custom_alias: params[:short_code])

    if short_url
      return render json: { error: 'URL has expired' }, status: :gone if short_url.expired?

      redirect_to short_url.long_url, allow_other_host: true
    else
      render json: { error: 'Not found' }, status: :not_found
    end
  end

  private

  def short_url_params
    params.permit(:long_url, :expires_at, :custom_alias)
  end

  def check_long_url
    return render json: { error: 'Long url must be provided' }, status: :bad_request if short_url_params[:long_url].blank?
  end
end

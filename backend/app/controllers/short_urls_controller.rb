class ShortUrlsController < ApplicationController
  include Pagy::Method

  skip_before_action :authenticate_user!, only: [:redirect_by_short_code, :redirect_by_custom_alias]
  before_action :check_long_url, only: [:create]

  def index
    filtered_urls = current_user.short_urls

    case params[:expired]
    when 'true', true
      filtered_urls = filtered_urls.expired
    when 'false', false
      filtered_urls = filtered_urls.active
    end

    if params[:q].present?
      query = "%#{params[:q]}%"

      filtered_urls = filtered_urls.where(
        'long_url ILIKE :q OR short_code ILIKE :q OR custom_alias ILIKE :q',
        q: query
      )
    end

    @pagy, short_urls = pagy(filtered_urls.order(created_at: :desc), items: params[:limit].to_i)

    render json: { data: short_urls, pagination: @pagy.data_hash }
  end

  def create
    short_url = ShortUrl.find_or_initialize_by(long_url: short_url_params[:long_url], user_id: current_user.id)
    short_url.expires_at = short_url_params[:expires_at].presence
    short_url.custom_alias = short_url_params[:custom_alias].presence

    if short_url.save
      render json: { short_code: short_url.custom_alias.presence || short_url.short_code }, status: :ok
    else
      render json: { errors: short_url.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def redirect_by_short_code
    short_url = ShortUrl.find_by(short_code: "s/#{params[:short_code]}")
    handle_redirect(short_url)
  end

  def redirect_by_custom_alias
    puts params.inspect
    short_url = ShortUrl.find_by(custom_alias: params[:custom_alias])
    handle_redirect(short_url)
  end

  private

  def short_url_params
    params.permit(:long_url, :expires_at, :custom_alias)
  end

  def check_long_url
    return render json: { error: 'Long url must be provided' }, status: :bad_request if short_url_params[:long_url].blank?
  end

  def handle_redirect(short_url)
    return render json: { error: 'Not found' }, status: :not_found unless short_url
    return render json: { error: 'URL has expired' }, status: :gone if short_url.expired?

    redirect_to short_url.long_url, allow_other_host: true
  end
end

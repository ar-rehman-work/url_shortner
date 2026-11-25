class ShortUrlsController < ApplicationController
  include Pagy::Method

  NOT_FOUND = '__not_found__'.freeze

  skip_before_action :authenticate_user!, only: [:redirect]
  before_action :check_long_url, only: [:create]

  def index
    filtered_urls = current_user.short_urls

    case params[:expired]
    when 'true', true
      filtered_urls = filtered_urls.expired
    when 'false', false
      filtered_urls = filtered_urls.unexpired
    end

    case params[:active]
    when 'true', true
      filtered_urls = filtered_urls.active
    when 'false', false
      filtered_urls = filtered_urls.inactive
    end

    case params[:custom]
    when 'true', true
      filtered_urls = filtered_urls.custom
    when 'false', false
      filtered_urls = filtered_urls.generated
    end

    if params[:q].present?
      query = "%#{params[:q]}%"

      filtered_urls = filtered_urls.where(
        'long_url ILIKE :q OR slug ILIKE :q',
        q: query
      )
    end

    @pagy, short_urls = pagy(filtered_urls.order(created_at: :desc), items: params[:limit].to_i)

    short_urls = short_urls.map do |short_url|
      short_url_response(short_url)
    end

    render json: { data: short_urls, pagination: @pagy.data_hash }
  end

  def create
    short_url = current_user.short_urls.build(
      long_url: short_url_params[:long_url],
      expires_at: short_url_params[:expires_at],
      slug: short_url_params[:custom_alias]
    )

    if short_url.save
      render json: short_url_response(short_url), status: :created
    else
      render json: { errors: short_url.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    short_url = current_user.short_urls.find(params[:id])

    short_url.long_url = short_url_params[:long_url] if short_url_params.key?(:long_url)
    short_url.expires_at = short_url_params[:expires_at] if short_url_params.key?(:expires_at)
    short_url.slug = short_url_params[:custom_alias] if short_url_params.key?(:custom_alias)

    if short_url.save
      render json: short_url_response(short_url), status: :ok
    else
      render json: { errors: short_url.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def redirect
    slug = params[:slug]
    cache_key = "sc:#{slug}"
    cached_data = Rails.cache.read(cache_key)

    redirect_data =
      if cached_data.present?
        cached_data
      else
        short_url = ShortUrl.find_by(slug: slug, active: true)

        data = NOT_FOUND
        expiry = 1.minute

        if short_url
          data = {
            id: short_url.id,
            long_url: short_url.long_url,
            expires_at: short_url.expires_at&.to_i
          }

          expiry = 5.hours
        end

        Rails.cache.write(cache_key, data, expires_in: expiry)

        data
      end

    handle_redirect(redirect_data)
  end

  private

  def short_url_params
    params.permit(:long_url, :expires_at, :custom_alias)
  end

  def check_long_url
    render json: { error: 'Long url must be provided' }, status: :bad_request if short_url_params[:long_url].blank?
  end

  def handle_redirect(redirect_data)
    return render json: { error: 'Not found' }, status: :not_found if redirect_data == NOT_FOUND

    if redirect_data[:expires_at] && Time.current.to_i >= redirect_data[:expires_at]
      return render json: { error: 'URL has expired' }, status: :gone
    end

    REDIS.pipelined do |pipeline|
      pipeline.sadd('active_click_urls', redirect_data[:id])
      pipeline.incr("url:#{redirect_data[:id]}:click_count")
      pipeline.set("url:#{redirect_data[:id]}:last_click_at", Time.current.to_i)
    end

    TrackClickJob.perform_later(
      redirect_data[:id],
      request.remote_ip,
      request.user_agent,
      request.referrer
    )

    redirect_to redirect_data[:long_url], allow_other_host: true
  end

  def short_url_response(short_url)
    {
      id: short_url.id,
      long_url: short_url.long_url,
      short_url: short_url.url,
      custom: short_url.custom,
      slug: short_url.slug,
      active: short_url.active,
      expires_at: short_url.expires_at,
      expired: short_url.expired?,
      updated_at: short_url.updated_at,
      created_at: short_url.created_at
    }
  end
end

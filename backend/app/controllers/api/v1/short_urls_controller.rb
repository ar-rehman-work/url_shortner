module Api
  module V1
    class ShortUrlsController < ApplicationController
      include Pagy::Method

      skip_before_action :authenticate_user!, only: [:redirect_by_short_code, :redirect_by_custom_alias]
      before_action :check_long_url, only: [:create]
      before_action :set_short_url, only: [:show, :update, :destroy]

      def index
        filtered_urls = current_user.short_urls

        case params[:expired]
        when 'true', true
          filtered_urls = filtered_urls.expired
        when 'false', false
          filtered_urls = filtered_urls.active
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
            'long_url ILIKE :q OR short_code ILIKE :q OR custom_alias ILIKE :q',
            q: query
          )
        end

        @pagy, short_urls = pagy(filtered_urls.order(created_at: :desc), items: params[:limit].to_i)

        render json: {
          data: short_urls.map { |short_url| serialize_short_url(short_url) },
          pagination: @pagy.data_hash
        }
      end

      def show
        render json: { data: serialize_short_url(@short_url) }, status: :ok
      end

      def create
        short_url = ShortUrl.find_or_initialize_by(
          long_url: short_url_params[:long_url],
          user_id: current_user.id
        )

        short_url.expires_at = short_url_params[:expires_at].presence
        short_url.custom_alias = short_url_params[:custom_alias].presence

        if short_url.save
          render json: { data: serialize_short_url(short_url) }, status: :created
        else
          render json: { errors: short_url.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @short_url.update(short_url_params)
          expire_short_url_cache(@short_url)

          render json: { data: serialize_short_url(@short_url) }, status: :ok
        else
          render json: { errors: @short_url.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        expire_short_url_cache(@short_url)

        @short_url.destroy

        head :no_content
      end

      def redirect_by_short_code
        short_url = Rails.cache.fetch(
          "short_url:s_#{params[:short_code]}",
          expires_in: 12.hours
        ) do
          ShortUrl.find_by(short_code: params[:short_code])
        end

        handle_redirect(short_url)
      end

      def redirect_by_custom_alias
        short_url = Rails.cache.fetch(
          "short_url:#{params[:custom_alias]}",
          expires_in: 12.hours
        ) do
          ShortUrl.find_by(custom_alias: params[:custom_alias])
        end

        handle_redirect(short_url)
      end

      private

      def set_short_url
        @short_url = current_user.short_urls.find_by(id: params[:id])

        return if @short_url

        render json: { error: 'Short URL not found' }, status: :not_found
      end

      def short_url_params
        params.permit(:long_url, :expires_at, :custom_alias)
      end

      def check_long_url
        return if short_url_params[:long_url].present?

        render json: { error: 'Long url must be provided' }, status: :bad_request
      end

      def serialize_short_url(short_url)
        {
          id: short_url.id,
          long_url: short_url.long_url,
          short_code: short_url.short_code,
          custom_alias: short_url.custom_alias,
          short_url: short_url.url,
          custom: short_url.custom_alias.present?,
          expires_at: short_url.expires_at,
          expired: short_url.expired?,
          click_count: short_url.click_count,
          last_click_at: short_url.last_click_at,
          created_at: short_url.created_at,
          updated_at: short_url.updated_at
        }
      end

      def expire_short_url_cache(short_url)
        Rails.cache.delete("short_url:s_#{short_url.short_code}") if short_url.short_code.present?
        Rails.cache.delete("short_url:#{short_url.custom_alias}") if short_url.custom_alias.present?
      end

      def handle_redirect(short_url)
        return render json: { error: 'Not found' }, status: :not_found unless short_url
        return render json: { error: 'URL has expired' }, status: :gone if short_url.expired?

        REDIS.pipelined do |pipeline|
          pipeline.sadd('active_click_urls', short_url.id)
          pipeline.incr("url:#{short_url.id}:click_count")
          pipeline.set("url:#{short_url.id}:last_click_at", Time.current.to_i)
        end

        TrackClickJob.perform_later(
          short_url.id,
          request.remote_ip,
          request.user_agent,
          request.referrer
        )

        redirect_to short_url.long_url, allow_other_host: true
      end
    end
  end
end

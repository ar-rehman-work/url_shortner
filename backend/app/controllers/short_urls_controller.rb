class ShortUrlsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:redirect]

  def create
    long_url = params[:long_url]

    if long_url.blank?
      return render json: { error: 'Long url must be provided' }, status: :bad_request
    end

    short_url = ShortUrl.find_or_initialize_by(long_url: long_url, user_id: current_user.id)

    if short_url.save
      render json: { short_code: short_url.short_code }, status: :ok
    else
      render json: { errors: short_url.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def redirect
    short_url = ShortUrl.find_by(short_code: params[:short_code])

    if short_url
      redirect_to short_url.long_url, allow_other_host: true
    else
      render json: { error: 'Not found' }, status: :not_found
    end
  end
end

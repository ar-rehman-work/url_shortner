class ApplicationController < ActionController::API
  before_action :authenticate_user!

  attr_reader :current_user

  private

  def authenticate_user!
    header = request.headers['Authorization']

    token = header.split(' ').last if header

    decoded = JwtService.decode(token)

    return render json: { error: 'Unauthorized' }, status: :unauthorized unless decoded

    @current_user = User.find(decoded['user_id'])
  rescue
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end

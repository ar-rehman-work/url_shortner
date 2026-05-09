class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:signup, :login]

  def signup
    user = User.new(user_params)

    if user.save
      token = JwtService.encode(user_id: user.id)

      render json: {
        message: 'User created successfully',
        token: token,
        user: user_response(user)
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      token = JwtService.encode(user_id: user.id)

      render json: {
        message: 'Login successful',
        token: token,
        user: user_response(user)
      }, status: :ok
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  private

  def user_params
    params.permit(:name, :email, :password)
  end

  def user_response(user)
    {
      id: user.id,
      name: user.name,
      email: user.email
    }
  end
end

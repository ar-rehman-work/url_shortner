require 'test_helper'

class AuthControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123'
    )
  end

  test 'signup creates user and returns token' do
    post '/signup', params: {
      name: 'New User',
      email: 'new@example.com',
      password: 'password123'
    }

    assert_response :created

    body = JSON.parse(response.body)
    assert_equal 'User created successfully', body['message']
    assert_not_nil body['token']
    assert_equal 'New User', body['user']['name']
    assert_equal 'new@example.com', body['user']['email']
  end

  test 'signup fails with invalid params' do
    post '/signup', params: {
      name: '',
      email: '',
      password: ''
    }

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)
    assert_not_nil body['errors']
    assert body['errors'].any?
  end

  test 'signup fails with duplicate email' do
    post '/signup', params: {
      name: 'Another User',
      email: 'test@example.com',
      password: 'password123'
    }

    assert_response :unprocessable_entity

    body = JSON.parse(response.body)

    assert_not_nil body['errors']
  end

  test 'login returns token with valid credentials' do
    post '/login', params: {
      email: 'test@example.com',
      password: 'password123'
    }

    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal 'Login successful', body['message']
    assert_not_nil body['token']
    assert_equal 'test@example.com', body['user']['email']
  end

  test 'login fails with wrong password' do
    post '/login', params: {
      email: 'test@example.com',
      password: 'wrongpassword'
    }

    assert_response :unauthorized

    body = JSON.parse(response.body)
    assert_equal 'Invalid email or password', body['error']
  end

  test 'login fails with non existent user' do
    post '/login', params: {
      email: 'missing@example.com',
      password: 'password123'
    }

    assert_response :unauthorized

    body = JSON.parse(response.body)
    assert_equal 'Invalid email or password', body['error']
  end

  test 'login fails with empty credentials' do
    post '/login', params: {
      email: '',
      password: ''
    }

    assert_response :unauthorized

    body = JSON.parse(response.body)
    assert_equal 'Invalid email or password', body['error']
  end
end

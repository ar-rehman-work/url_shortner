require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123'
    )
  end

  test 'valid user' do
    assert @user.valid?
  end

  test 'invalid without name' do
    @user.name = nil

    assert_not @user.valid?
    assert_includes @user.errors[:name], "can't be blank"
  end

  test 'invalid when name exceeds max length' do
    @user.name = 'a' * 101

    assert_not @user.valid?
  end

  test 'invalid without email' do
    @user.email = nil

    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test 'invalid email format' do
    @user.email = 'invalid-email'

    assert_not @user.valid?
  end

  test 'email uniqueness validation' do
    @user.save!

    duplicate_user = User.new(
      name: 'Another User',
      email: 'test@example.com',
      password: 'password123'
    )

    assert_not duplicate_user.valid?
  end

  test 'invalid without password' do
    @user.password = nil

    assert_not @user.valid?
  end

  test 'authenticates with correct password' do
    user = User.create!(
      name: 'Test User',
      email: 'auth@example.com',
      password: 'password123'
    )

    assert user.authenticate('password123')
  end

  test 'does not authenticate with wrong password' do
    user = User.create!(
      name: 'Test User',
      email: 'auth2@example.com',
      password: 'password123'
    )

    assert_not user.authenticate('wrongpassword')
  end
end

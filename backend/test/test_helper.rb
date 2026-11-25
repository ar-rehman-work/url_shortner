ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'mocha/minitest'
require 'set'

class TestRedis
  def initialize
    @sets = Hash.new { |hash, key| hash[key] = Set.new }
    @values = {}
    @mutex = Mutex.new
  end

  def pipelined
    yield self
  end

  def sadd(key, value)
    @mutex.synchronize { @sets[key] << value.to_s }
  end

  def smembers(key)
    @mutex.synchronize { @sets[key].to_a }
  end

  def srem(key, value)
    @mutex.synchronize { @sets[key].delete(value.to_s) }
  end

  def incr(key)
    @mutex.synchronize do
      @values[key] = @values.fetch(key, 0).to_i + 1
    end
  end

  def set(key, value)
    @mutex.synchronize { @values[key] = value }
  end

  def getdel(key)
    @mutex.synchronize { @values.delete(key) }
  end

  def clear
    @mutex.synchronize do
      @sets.clear
      @values.clear
    end
  end
end

Object.send(:remove_const, :REDIS)
REDIS = TestRedis.new
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1, with: :threads)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "active_record"
require "active_support"
require "active_support/core_ext/kernel/reporting"

silence_warnings do
  require "iruby"
end

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)

ActiveRecord::Base.logger = logger
ActiveRecord::Migration.verbose = ENV["VERBOSE"]

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :name
  end
end

class User < ActiveRecord::Base
end

class Minitest::Test
  def assert_vector(exp, act, type: nil)
    assert_kind_of Rover::Vector, act
    assert_equal type, act.type if type
    assert_equal exp.to_a, act.to_a
  end

  def assert_vector_in_delta(exp, act, type: nil)
    assert_kind_of Rover::Vector, act
    assert_equal type, act.type if type
    assert_elements_in_delta exp.to_a, act.to_a
  end

  def assert_elements_in_delta(expected, actual)
    assert_equal expected.size, actual.size
    expected.zip(actual) do |exp, act|
      assert_in_delta exp, act
    end
  end
end

require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "active_record"

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)

ActiveRecord::Base.logger = logger

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Migration.create_table :users do |t|
  t.string :name
end

class User < ActiveRecord::Base
end

class Minitest::Test
  def assert_vector(exp, act)
    assert_kind_of Rover::Vector, act
    assert_equal exp.to_a, act.to_a
  end
end

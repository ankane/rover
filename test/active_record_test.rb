require_relative "test_helper"

class ActiveRecordTest < Minitest::Test
  def setup
    User.delete_all
  end

  def test_model
    users = 3.times.map { |i| User.create!(name: "User #{i}") }
    df = Rover::DataFrame.new(User).sort_by { |row| row["id"] }
    assert_equal ["id", "name"], df.vector_names
    assert_vector users.map(&:id), df["id"]
    assert_vector users.map(&:name), df["name"]
  end

  def test_relation
    users = 3.times.map { |i| User.create!(name: "User #{i}") }
    df = Rover::DataFrame.new(User.order(:id))
    assert_equal ["id", "name"], df.vector_names
    assert_vector users.map(&:id), df["id"]
    assert_vector users.map(&:name), df["name"]
  end

  def test_result
    users = 3.times.map { |i| User.create!(name: "User #{i}") }
    df = Rover::DataFrame.new(User.connection.select_all("SELECT * FROM users ORDER BY id"))
    assert_equal ["id", "name"], df.vector_names
    assert_vector users.map(&:id), df["id"]
    assert_vector users.map(&:name), df["name"]
  end

  def test_connection_leasing
    ActiveRecord::Base.connection_handler.clear_active_connections!
    assert_nil ActiveRecord::Base.connection_pool.active_connection?
    ActiveRecord::Base.connection_pool.with_connection do
      Rover::DataFrame.new(User.order(:id))
    end
    assert_nil ActiveRecord::Base.connection_pool.active_connection?
  end
end

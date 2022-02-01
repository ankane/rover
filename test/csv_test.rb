require_relative "test_helper"

class CsvTest < Minitest::Test
  def test_read_csv
    df = Rover.read_csv("test/support/data.csv")
    assert_equal ["a", "b"], df.vector_names
  end

  def test_read_csv_default_types
    df = Rover.read_csv("test/support/types.csv")
    assert_equal :int, df.types["a"]
    assert_equal :object, df.types["b"]
    assert_equal :float, df.types["c"]
  end

  def test_read_csv_empty
    df = Rover.read_csv("test/support/empty.csv")
    assert_empty df
    assert_empty df.keys
  end

  def test_read_csv_empty_headers
    df = Rover.read_csv("test/support/empty.csv", headers: [])
    assert_empty df
    assert_empty df.keys
  end

  def test_read_csv_headers
    df = Rover.read_csv("test/support/data.csv", headers: ["c", "d"])
    assert_equal ["c", "d"], df.vector_names
    assert_equal 4, df.size
  end

  def test_read_csv_headers_false
    error = assert_raises(ArgumentError) do
      Rover.read_csv("test/support/data.csv", headers: false)
    end
    assert_equal "Must specify headers", error.message
  end

  def test_read_csv_headers_too_few
    error = assert_raises(ArgumentError) do
      Rover.read_csv("test/support/data.csv", headers: ["a"])
    end
    assert_equal "Expected 2 headers, got 1", error.message
  end

  # TODO raise error in 0.3.0?
  def test_read_csv_headers_too_many
    df = Rover.read_csv("test/support/data.csv", headers: ["a", "b", "c"])
    assert_equal ["a", "b", "c"], df.keys
  end

  # TODO decide on best approach, but this is current behavior
  def test_read_csv_columns_too_many
    df = Rover.read_csv("test/support/columns.csv")
    expected = Rover::DataFrame.new({"one" => ["one", "one"], "unnamed" => ["two", "two"]})
    assert_equal expected, df
  end

  def test_read_csv_headers_unnamed
    df = Rover.read_csv("test/support/unnamed.csv")
    # TODO change last value to unnamed4 in 0.3.0
    assert_equal ["unnamed2", "unnamed", "unnamed3", ""], df.keys
  end

  def test_parse_csv_headers_unnamed
    df = Rover.parse_csv(",unnamed,,unnamed3")
    assert_equal ["unnamed2", "unnamed", "unnamed4", "unnamed3"], df.keys
  end

  def test_parse_csv
    df = Rover.parse_csv("a,b\n1,one\n2,two\n3,three\n")
    assert_equal ["a", "b"], df.vector_names
  end
end

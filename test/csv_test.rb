require_relative "test_helper"

class CsvTest < Minitest::Test
  def test_read_csv
    df = Rover.read_csv("test/support/data.csv")
    expected = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal expected, df
  end

  def test_parse_csv
    df = Rover.parse_csv("a,b\n1,one\n2,two\n3,three\n")
    expected = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal expected, df
  end

  def test_default_types
    df = Rover.read_csv("test/support/types.csv")
    assert_equal :int64, df.types["a"]
    assert_equal :object, df.types["b"]
    assert_equal :float64, df.types["c"]
  end

  def test_types
    df = Rover.read_csv("test/support/types.csv", types: {"a" => :int8})
    assert_equal :int8, df.types["a"]
  end

  def test_empty
    df = Rover.read_csv("test/support/empty.csv")
    assert_empty df
    assert_empty df.keys
  end

  def test_empty_headers
    df = Rover.read_csv("test/support/empty.csv", headers: [])
    assert_empty df
    assert_empty df.keys
  end

  def test_headers
    df = Rover.read_csv("test/support/data.csv", headers: ["c", "d"])
    assert_equal ["c", "d"], df.vector_names
    assert_equal 4, df.size
  end

  def test_headers_true
    df = Rover.read_csv("test/support/data.csv", headers: true)
    assert_equal ["a", "b"], df.vector_names
    assert_equal 3, df.size
  end

  def test_headers_false
    error = assert_raises(ArgumentError) do
      Rover.read_csv("test/support/data.csv", headers: false)
    end
    assert_equal "Must specify headers", error.message
  end

  def test_headers_too_few
    error = assert_raises(ArgumentError) do
      Rover.read_csv("test/support/data.csv", headers: ["a"])
    end
    assert_equal "Expected 2 headers, got 1", error.message
  end

  # TODO raise error in 0.3.0?
  def test_headers_too_many
    df = Rover.read_csv("test/support/data.csv", headers: ["a", "b", "c"])
    assert_equal ["a", "b", "c"], df.keys
  end

  # TODO decide on best approach, but this is current behavior
  def test_columns_too_many
    df = Rover.read_csv("test/support/columns.csv")
    expected = Rover::DataFrame.new({"one" => ["one", "one"], "unnamed" => ["two", "two"]})
    assert_equal expected, df
  end

  def test_headers_unnamed
    df = Rover.read_csv("test/support/unnamed.csv")
    # TODO change last value to unnamed4 in 0.3.0
    assert_equal ["unnamed2", "unnamed", "unnamed3", ""], df.keys
  end

  def test_headers_unnamed_advanced
    df = Rover.parse_csv(",unnamed,,unnamed3")
    assert_equal ["unnamed2", "unnamed", "unnamed4", "unnamed3"], df.keys
  end

  def test_headers_duplicate
    df = Rover.parse_csv("a,a\n1,2\n")
    assert_equal Rover::DataFrame.new({"a" => [1]}), df
  end

  def test_to_csv
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal "a,b\n1,one\n2,two\n3,three\n", df.to_csv
  end
end

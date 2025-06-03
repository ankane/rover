require_relative "test_helper"

class ParquetTest < Minitest::Test
  def setup
    skip unless ENV["TEST_PARQUET"]
  end

  def test_read_parquet
    df = Rover.read_parquet("test/support/data.parquet")
    expected = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal expected, df
  end

  def test_parse_parquet
    df = Rover.parse_parquet(File.binread("test/support/data.parquet"))
    expected = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal expected, df
  end

  # uint32 is read as int64
  def test_default_types
    df = Rover.read_parquet("test/support/types.parquet")
    expected = [:int64, :int32, :int16, :int8, :uint64, :int64, :uint16, :uint8, :float64, :float32, :object, :bool]
    assert_equal expected, df.types.values
  end

  def test_types
    df = Rover.read_parquet("test/support/data.parquet", types: {"a" => :int8})
    assert_equal :int8, df.types["a"]
  end

  def test_types_symbol
    df = Rover.read_parquet("test/support/data.parquet", types: {a: :int8})
    assert_equal :int8, df.types["a"]
  end

  def test_null
    error = assert_raises do
      Rover.read_parquet("test/support/null.parquet")
    end
    assert_equal "Nulls not supported for int32 column: a", error.message

    df = Rover.read_parquet("test/support/null.parquet", types: {"a" => :object})
    assert_vector [1, nil, 3], df["a"]

    df = Rover.read_parquet("test/support/null.parquet", types: {"a" => :float})
    assert df["a"][1].nan?
  end

  def test_to_parquet
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal df, Rover.parse_parquet(df.to_parquet)
  end

  def test_to_parquet_types
    df = Rover.read_parquet("test/support/types.parquet")
    assert df.to_parquet
  end
end

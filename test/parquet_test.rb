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

  # uint32 is read as int
  def test_read_parquet_types
    df = Rover.read_parquet("test/support/types.parquet")
    expected = [:int, :int32, :int16, :int8, :uint, :int, :uint16, :uint8, :float, :float32]
    assert_equal expected, df.types.values
  end

  def test_to_parquet
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal df, Rover.parse_parquet(df.to_parquet)
  end
end

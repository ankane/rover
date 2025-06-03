require_relative "test_helper"

class GroupTest < Minitest::Test
  def test_group
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "one", "two"]})
    expected = Rover::DataFrame.new({"b" => ["one", "two"], "count" => [2, 1]})
    assert_equal expected, df.group("b").count
  end

  def test_symbol
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "one", "two"]})
    expected = Rover::DataFrame.new({"b" => ["one", "two"], "count" => [2, 1]})
    assert_equal expected, df.group(:b).count
  end

  def test_nil
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "one", nil]})
    expected = Rover::DataFrame.new({"b" => ["one", nil], "count" => [2, 1]})
    assert_equal expected, df.group("b").count
  end

  def test_multiple
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "one", "two"]})
    expected = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "one", "two"], "count" => [1, 1, 1]})
    assert_equal expected, df.group(["a", "b"]).count
  end

  def test_multiple_args
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "one", "two"]})
    expected = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "one", "two"], "count" => [1, 1, 1]})
    assert_equal expected, df.group("a", "b").count
  end

  def test_multiple_calls
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "one", "two"]})
    expected = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "one", "two"], "count" => [1, 1, 1]})
    assert_equal expected, df.group("a").group("b").count
  end

  def test_empty
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "one", "two"]})
    error = assert_raises(ArgumentError) do
      df.group([])
    end
    assert_equal "No columns given", error.message
  end

  def test_missing_keys
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "one", "two"]})
    error = assert_raises(ArgumentError) do
      df.group("c")
    end
    assert_equal "Missing keys: c", error.message
  end

  def test_max
    df = Rover::DataFrame.new({"a" => [1, 100, 3], "b" => ["one", "one", "two"]})
    expected = Rover::DataFrame.new({"b" => ["one", "two"], "max_a" => [100, 3]})
    assert_equal expected, df.group("b").max("a")
  end

  def test_min
    df = Rover::DataFrame.new({"a" => [1, 100, 3], "b" => ["one", "one", "two"]})
    expected = Rover::DataFrame.new({"b" => ["one", "two"], "min_a" => [1, 3]})
    assert_equal expected, df.group("b").min("a")
  end

  # uses Bessel's correction for now since that's all Numo supports
  def test_std
    df = Rover::DataFrame.new({"a" => [1, 2, 2, 3, 4, 6], "b" => ["one", "one", "two", "one", "two", "two"]})
    expected = Rover::DataFrame.new({"b" => ["one", "two"], "std_a" => [1, 2]})
    assert_equal expected, df.group("b").std("a")
  end

  # uses Bessel's correction for now since that's all Numo supports
  def test_var
    df = Rover::DataFrame.new({"a" => [1, 2, 4, 5], "b" => ["one", "two", "two", "one"]})
    expected = Rover::DataFrame.new({"b" => ["one", "two"], "var_a" => [8, 2]})
    assert_equal expected, df.group("b").var("a")
  end
end

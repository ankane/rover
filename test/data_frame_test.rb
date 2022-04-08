require_relative "test_helper"

class DataFrameTest < Minitest::Test
  # constructors

  def test_data_frame
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal ["a", "b"], Rover::DataFrame.new(df).keys
  end

  def test_array
    df = Rover::DataFrame.new([{a: 1, b: "one"}, {a: 2, b: "two"}, {a: 3, b: "three"}])
    assert_vector [1, 2, 3], df[:a]
    assert_vector ["one", "two", "three"], df[:b]
    assert_equal 3, df.size
    assert_equal 3, df.length
    assert_equal 3, df.count
    assert df.any?
    assert !df.empty?
    assert_vector [1, 2], df.first(2)[:a]
    assert_equal [:a, :b], df.vector_names
    assert_equal [:a, :b], df.keys
    assert_equal ({a: :int64, b: :object}), df.types
    assert df.include?(:a)
    assert !df.include?(:c)
  end

  def test_array_missing
    df = Rover::DataFrame.new([{b: "one"}, {a: 2, b: "two"}, {a: 3}])
    assert df[:a][0].nan?
    assert_equal 2, df[:a][1]
    assert_equal 3, df[:a][2]
    assert_equal "one", df[:b][0]
    assert_equal "two", df[:b][1]
    assert_nil df[:b][2]
  end

  def test_array_invalid
    error = assert_raises(ArgumentError) do
      Rover::DataFrame.new([1, 2])
    end
    assert_equal "Array elements must be hashes", error.message
  end

  def test_hash
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_vector [1, 2, 3], df["a"]
    assert_vector ["one", "two", "three"], df["b"]
    assert_equal 3, df.size
    assert_vector [1, 2], df.first(2)["a"]
    assert_equal ["a", "b"], df.vector_names
    assert df.include?("a")
    assert !df.include?("c")
  end

  def test_hash_key
    error = assert_raises(ArgumentError) do
      Rover::DataFrame.new(1 => 1..3)
    end
    assert_equal "Key must be a String or Symbol, given Integer", error.message
  end

  def test_invalid_data
    error = assert_raises(ArgumentError) do
      Rover::DataFrame.new(1)
    end
    assert_equal "Cannot cast to data frame: Integer", error.message
  end

  def test_different_sizes
    error = assert_raises(ArgumentError) do
      Rover::DataFrame.new({"a" => [1, 2, 3], "b" => [1, 2]})
    end
    assert_equal "Different sizes: [3, 2]", error.message
  end

  def test_scalar
    df = Rover::DataFrame.new({"a" => 1, "b" => [1, 2, 3]})
    assert_vector [1, 1, 1], df["a"]
    df["c"] = true
    assert_vector [true, true, true], df["c"]
    df["c"] = false
    assert_vector [false, false, false], df["c"]
  end

  # to methods

  def test_to_a
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal [{"a" => 1, "b" => "one"}, {"a" => 2, "b" => "two"}, {"a" => 3, "b" => "three"}], df.to_a
  end

  def test_to_h
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal ({"a" => [1, 2, 3], "b" => ["one", "two", "three"]}), df.to_h
  end

  def test_to_numo
    df = Rover::DataFrame.new({"a" => 1..3, "b" => 4..6, "c" => 7..9})
    assert_equal [[1, 4, 7], [2, 5, 8], [3, 6, 9]], df.to_numo.to_a
  end

  # TODO use to_iruby when released
  def test_to_html
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_match "<table>", df.to_html
  end

  # other

  def test_one_hot
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "three", "three"]})
    expected = Rover::DataFrame.new({
      "a" => [1, 2, 3],
      "b_one" => [1, 0, 0],
      "b_three" => [0, 1, 1]
    })
    assert_equal expected, df.one_hot
  end

  def test_one_hot_drop
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "three", "three"]})
    expected = Rover::DataFrame.new({
      "a" => [1, 2, 3],
      "b_three" => [0, 1, 1]
    })
    assert_equal expected, df.one_hot(drop: true)
  end

  def test_one_hot_non_string
    error = assert_raises(ArgumentError) do
      Rover::DataFrame.new({"a" => [Time.now]}).one_hot
    end
    assert_equal "All elements must be numeric or strings", error.message
  end

  def test_clear
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    df.clear
    assert_equal 0, df.size
    assert_empty df.keys
    assert df.empty?
    assert !df.any?
  end

  def test_sort_by
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    sorted = df.sort_by { |r| r["b"] }
    assert_vector [1, 3, 2], sorted["a"]
    assert_vector ["one", "three", "two"], sorted["b"]
    assert_vector [1, 2, 3], df["a"]
    assert_vector ["one", "two", "three"], df["b"]
  end

  def test_sort_by!
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    df.sort_by! { |r| r["b"] }
    assert_vector [1, 3, 2], df["a"]
    assert_vector ["one", "three", "two"], df["b"]
  end

  def test_max
    df = Rover::DataFrame.new({"a" => [1, 100, 3]})
    assert_equal 100, df.max("a")
  end

  def test_max_missing
    error = assert_raises(KeyError) do
      Rover::DataFrame.new({"a" => [1, 100, 3]}).max("b")
    end
    assert_equal "Missing column: b", error.message
  end

  def test_min
    df = Rover::DataFrame.new({"a" => [1, 100, 3]})
    assert_equal 1, df.min("a")
  end

  def test_mean
    df = Rover::DataFrame.new({"a" => [1, 2, 6]})
    assert_equal 3, df.mean("a")
  end

  def test_median
    df = Rover::DataFrame.new({"a" => [1, 2, 6]})
    assert_equal 2, df.median("a")
  end

  def test_percentile
    df = Rover::DataFrame.new({"a" => [1, 2, 3, 10]})
    assert_equal 2.5, df.percentile("a", 50)
  end

  def test_sum
    df = Rover::DataFrame.new({"a" => [1, 2, 6]})
    assert_equal 9, df.sum("a")
  end

  # TODO better test
  def test_sample
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal 1, df.sample.size
    assert_equal 2, df.sample(2).size
    assert_equal 2, df.sample(2, random: Random.new(123)).size
  end

  def test_empty_size
    assert_equal 0,  Rover::DataFrame.new.size
  end

  def test_concat
    df = Rover::DataFrame.new({"a" => 1..3})
    df2 = Rover::DataFrame.new({"b" => 4..6})

    c1 = df + df
    assert_equal 6, c1.size
    assert_equal ["a"], c1.vector_names
    assert_vector [1, 2, 3, 1, 2, 3], c1["a"]

    df.concat(df2)
    assert_equal 6, df.size
    assert_equal ["a", "b"], df.vector_names
  end

  def test_merge
    df = Rover::DataFrame.new({"a" => 1..3, "b" => 4..6})
    df2 = Rover::DataFrame.new({"b" => 7..9, "c" => 10..12})
    merged = df.merge(df2)
    assert_equal ["a", "b"], df.keys
    assert_equal ["b", "c"], df2.keys
    assert_equal ["a", "b", "c"], merged.keys
    assert_vector 1..3, merged["a"]
    assert_vector 7..9, merged["b"]
    assert_vector 10..12, merged["c"]
  end

  def test_merge!
    df = Rover::DataFrame.new({"a" => 1..3, "b" => 4..6})
    df2 = Rover::DataFrame.new({"b" => 7..9, "c" => 10..12})
    df.merge!(df2)
    assert_equal ["a", "b", "c"], df.keys
    assert_vector 1..3, df["a"]
    assert_vector 7..9, df["b"]
    assert_vector 10..12, df["c"]
  end

  def test_merge_different_sizes
    df = Rover::DataFrame.new({"a" => 1..3})
    df2 = Rover::DataFrame.new({"b" => [1]})
    error = assert_raises(ArgumentError) do
      df.merge(df2)
    end
    assert_equal "Size mismatch (given 1, expected 3)", error.message
  end

  def test_delete
    df = Rover::DataFrame.new({"a" => 1..3, "b" => "a".."c"})
    assert_vector [1, 2, 3], df.delete("a")
    assert_equal ["b"], df.vector_names
  end

  def test_except
    df = Rover::DataFrame.new({"a" => 1..3, "b" => "a".."c", "c" => 1..3})
    assert_equal ["a"], df.except("b", "c").vector_names
    assert_equal ["a", "b", "c"], df.vector_names
  end

  def test_except!
    df = Rover::DataFrame.new({"a" => 1..3, "b" => "a".."c", "c" => 1..3})
    df.except!("b", "c")
    assert_equal ["a"], df.vector_names
  end

  def test_select
    df = Rover::DataFrame.new({"a" => 1..3, "b" => 1..3, "c" => 1..3})
    assert_equal ["a", "b"], df[["a", "b"]].vector_names
  end

  def test_reader
    df = Rover::DataFrame.new({"a" => [1, 2, 3]})
    assert_vector [2], df[1]["a"]
    assert_vector [1, 2], df[0..1]["a"]
    assert_vector [1, 3], df[[0, 2]]["a"]
  end

  def test_reader_where
    df = Rover::DataFrame.new({"a" => [1, 2, 3]})
    where = Rover::Vector.new([true, false, true])
    assert_vector [1, 3], df[where]["a"]
  end

  def test_reader_missing_column
    df = Rover::DataFrame.new({"hello" => [1, 2, 3], "hello2" => ["one", "two", "three"]})
    error = assert_raises(KeyError) do
      df[["hello", "hello3"]]
    end
    assert_match "Missing column: hello3", error.message
    assert_match %{Did you mean?  "hello"}, error.message
    assert_match "hello2", error.message
  end

  def test_setter
    df = Rover::DataFrame.new({"a" => [1, 2, 3]})
    df["b"] = 1
    assert_vector [1, 1, 1], df["b"]
    error = assert_raises(ArgumentError) do
      df["c"] = [1, 2]
    end
    assert_equal "Size mismatch (given 2, expected 3)", error.message
  end

  def test_setter_empty
    df = Rover::DataFrame.new
    df["a"] = [1, 2, 3]
    assert_vector [1, 2, 3], df["a"]
  end

  def test_filtering_and
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_vector [2], df[(df["a"] > 1) & (df["b"] == "two")]["a"]
  end

  def test_filtering_or
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_vector [2, 3], df[(df["a"] > 2) | (df["b"] == "two")]["a"]
  end

  def test_filtering_xor
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_vector [3], df[(df["a"] > 1) ^ (df["b"] == "two")]["a"]
  end

  def test_to_s
    df = Rover::DataFrame.new({"a" => 1..5, "b" => ["one", "two", "three", "four", "five"]})
    assert_equal "  a      b\n  1    one\n  2    two\n  3  three\n  4   four\n  5   five", df.to_s
  end

  def test_to_s_summary
    df = Rover::DataFrame.new({"a" => 1..99})
    assert_equal "  a\n  1\n  2\n  3\n  4\n  5\n...\n 95\n 96\n 97\n 98\n 99", df.to_s
  end

  def test_to_s_empty
    df = Rover::DataFrame.new
    assert_equal "#<Rover::DataFrame>", df.to_s
  end

  def test_inspect
    df = Rover::DataFrame.new(
        float: [1,Float::NAN,Float::INFINITY, 4, 5],
        int:   [1, 2, 3, 4, 5],
        str:   ["A", "B", "C", nil, ""],
        obj:   [true, false, true, nil, false],
        bit:   Numo::Bit[1,0,1,0,1],
      )
    assert_equal %(\
Rover::DataFrame : 5 observations(rows) of 5 variables(columns).
Variables : 2 numeric, 2 objects, 1 bool
# key    type    level data_preview
1 :float float64     5 {1.0=>1, NaN=>1, Infinity=>1, 4.0=>1, 5.0=>1}
2 :int   int64       5 {1=>1, 2=>1, 3=>1, 4=>1, 5=>1}
3 :str   object      5 {"A"=>1, "B"=>1, "C"=>1, nil=>1, ""=>1}
4 :obj   object      3 {true=>2, false=>2, nil=>1}
5 :bit   bool        2 {1=>3, 0=>2}
), df.inspect
  end
   
  def test_inspect_large_df
    df = Rover::DataFrame.new(a: 1..100000)
    assert_equal %(\
Rover::DataFrame : 100000 observations(rows) of 1 variable(column).
Variable : 1 numeric
# key type  level  data_preview
1 :a  int64 100000 [1, 2, 3, 4, 5, ...]
), df.inspect
  end

  def test_inspect_empty
    df = Rover::DataFrame.new
    assert_equal "#<Rover::DataFrame (empty)>", df.inspect
  end

  def test_equal
    df = Rover::DataFrame.new({a: 1..3})
    assert_equal df, Rover::DataFrame.new({a: 1..3})
    refute_equal df, Rover::DataFrame.new({b: 1..3})
    refute_equal df, Rover::DataFrame.new({a: 1..3, b: 1..3})
    refute_equal df, Rover::DataFrame.new({a: 2..4})
  end

  def test_each_row
    df = Rover::DataFrame.new({a: 1..3})
    rows = []
    df.each_row do |row|
      rows << row
    end
    assert_equal [{a: 1}, {a: 2}, {a: 3}], rows
  end
  def test_each_row_enum
    df = Rover::DataFrame.new({a: 1..3})
    rows = df.each_row.map { |r| r }
    assert_equal [{a: 1}, {a: 2}, {a: 3}], rows
  end

  def test_arguments
    error = assert_raises(ArgumentError) do
      Rover::DataFrame.new(1, 2, types: {})
    end
    assert_equal "wrong number of arguments (given 2, expected 0..1)", error.message
  end

  def test_arguments_types_argument
    assert_equal [:types], Rover::DataFrame.new({types: {}}).vector_names
  end

  # this shouldn't be the case, but we can't use keyword arguments
  def test_arguments_types_keyword
    assert_equal [:types], Rover::DataFrame.new(types: {}).vector_names
  end

  def test_vector_map!
    df = Rover::DataFrame.new({"a" => [10, 20, 30]})
    assert_equal :int64, df["a"].type
    assert_equal :int64, df.types["a"]

    df["a"].map! { |v| v + 0.5 }

    assert_vector [10.5, 20.5, 30.5], df["a"]
    assert_equal :float64, df["a"].type
    assert_equal :float64, df.types["a"]
  end

  def test_first
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal Rover::DataFrame.new({"a" => [1], "b" => ["one"]}), df.first
    assert_equal Rover::DataFrame.new({"a" => [1, 2], "b" => ["one", "two"]}), df.first(2)
  end

  def test_last
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal Rover::DataFrame.new({"a" => [3], "b" => ["three"]}), df.last
    assert_equal Rover::DataFrame.new({"a" => [2, 3], "b" => ["two", "three"]}), df.last(2)
  end

  def test_head
    df = Rover::DataFrame.new({"a" => 1..10})
    assert_equal Rover::DataFrame.new({"a" => 1..5}), df.head
    assert_equal Rover::DataFrame.new({"a" => 1..3}), df.head(3)
  end

  def test_tail
    df = Rover::DataFrame.new({"a" => 1..10})
    assert_equal Rover::DataFrame.new({"a" => 6..10}), df.tail
    assert_equal Rover::DataFrame.new({"a" => 8..10}), df.tail(3)
  end

  def test_clone
    df = Rover::DataFrame.new({"a" => [1, 2, 3]})
    df2 = df.clone
    df["a"][1] = 0
    assert_vector [1, 0, 3], df2["a"]
  end

  def test_dup
    df = Rover::DataFrame.new({"a" => [1, 2, 3]})
    df2 = df.dup
    df["a"][1] = 0
    assert_vector [1, 0, 3], df2["a"]
  end

  def test_deep_dup
    df = Rover::DataFrame.new({"a" => [1, 2, 3]})
    df2 = df.deep_dup
    df["a"][1] = 0
    assert_vector [1, 2, 3], df2["a"]
  end
end

require_relative "test_helper"

class VectorTest < Minitest::Test
  def test_works
    vector = Rover::Vector.new([1, 2, 3])
    assert_vector [1, 2, 3], vector
    assert_equal 3, vector.size
    assert_equal 3, vector.count
    assert_equal 3, vector.length
    assert_vector [1, 2], vector.first(2)
    assert_vector [2, 3], vector.last(2)
    assert_equal 1, vector[0]
    # TODO change to vector
    assert_equal [1, 2], vector[0..1].to_a
    assert_equal [2, 3], vector[1..-1].to_a
    assert_equal [2, 3], vector[1..].to_a
    assert_equal [1, 3], vector[[0, 2]].to_a
  end

  def test_array
    assert_vector [1, 2, 3], Rover::Vector.new([1, 2, 3])
  end

  def test_range
    assert_vector [1, 2, 3], Rover::Vector.new(1..3)
  end

  def test_sort
    assert_vector [1, 2, 3], Rover::Vector.new([3, 1, 2]).sort
    assert_vector ["a", "b", "c"], Rover::Vector.new(["b", "c", "a"]).sort
  end

  def test_numeric
    assert Rover::Vector.new(1..3).numeric?
    assert !Rover::Vector.new(["b", "c", "a"]).numeric?
    assert !Rover::Vector.new([true, true, false]).numeric?
  end

  def test_add_strings
    a = Rover::Vector.new(["a", "b", "c"])
    b = Rover::Vector.new(["d", "e", "f"])
    assert_vector ["ad", "be", "cf"], a + b
  end

  def test_missing
    assert_vector [false, true, false], Rover::Vector.new([1, nil, 3]).missing
    assert_vector [false, true, false], Rover::Vector.new(["one", nil, "three"]).missing
  end

  def test_one_hot
    vector = Rover::Vector.new(["one", "three", "three"])
    expected = Rover::DataFrame.new({
      "one" => [1, 0, 0],
      "three" => [0, 1, 1]
    })
    assert_equal expected, vector.one_hot
  end

  def test_crosstab
    a = Rover::Vector.new([1, 2, 3, 1])
    b = Rover::Vector.new(["a", "b", "c", "a"])
    df = a.crosstab(b)
    assert_vector [1, 2, 3], df["_"]
    assert_vector [2, 0, 0], df["a"]
    assert_vector [0, 1, 0], df["b"]
    assert_vector [0, 0, 1], df["c"]
  end

  def test_head
    vector = Rover::Vector.new(1..6)
    assert_vector [1, 2, 3, 4, 5], vector.head
    assert_vector [1, 2, 3], vector.head(3)
    assert_vector [1, 2, 3, 4], vector.head(-2)
  end

  def test_tail
    vector = Rover::Vector.new(1..6)
    assert_vector [2, 3, 4, 5, 6], vector.tail
    assert_vector [4, 5, 6], vector.tail(3)
    assert_vector [3, 4, 5, 6], vector.tail(-2)
  end

  def test_operations
    vector = Rover::Vector.new([10, 20, 30])
    assert_vector [15, 25, 35], vector + 5
    assert_vector [5, 15, 25], vector - 5
    assert_vector [50, 100, 150], vector * 5
    assert_vector [2, 4, 6], vector / 5
    assert_vector [1, 2, 0], vector % 3
    assert_vector [100, 400, 900], vector ** 2
  end

  def test_operations_scalar
    vector = Rover::Vector.new([10, 20, 30])
    assert_vector [15, 25, 35], 5 + vector
    assert_vector [25, 15, 5], 35 - vector
    assert_vector [50, 100, 150], 5 * vector
    assert_vector [6, 3, 2], 60 / vector
  end

  def test_operations_vector
    a = Rover::Vector.new([10, 20, 30])
    b = Rover::Vector.new([1, 2, 3])
    assert_vector [11, 22, 33], a + b
    assert_vector [9, 18, 27], a - b
    assert_vector [10, 40, 90], a * b
    assert_vector [10, 10, 10], a / b
    assert_vector [0, 0, 0], a % b
    assert_vector [10, 400, 27000], a ** b
  end

  def test_operations_array
    a = Rover::Vector.new([10, 20, 30])
    b = [1, 2, 3]
    assert_vector [11, 22, 33], a + b
    assert_vector [9, 18, 27], a - b
    assert_vector [10, 40, 90], a * b
    assert_vector [10, 10, 10], a / b
    assert_vector [0, 0, 0], a % b
    assert_vector [10, 400, 27000], a ** b
  end

  # TODO use true division in 0.4.0?
  def test_division_int
    a = Rover::Vector.new([1, 3, 5])
    assert_vector [0, 1, 2], a / 2, type: :int64
  end

  # TODO use true division in 0.4.0?
  def test_division_int_vector
    a = Rover::Vector.new([1, 3, 5])
    b = Rover::Vector.new([2, 2, 2])
    assert_vector [0, 1, 2], a / b
  end

  def test_division_float
    a = Rover::Vector.new([1.0, 3, 5])
    assert_vector_in_delta [0.5, 1.5, 2.5], a / 2, type: :float64
  end

  def test_division_float_vector
    a = Rover::Vector.new([1, 3, 5])
    b = Rover::Vector.new([2.0, 2, 2])
    assert_vector_in_delta [0.5, 1.5, 2.5], a / b, type: :float64
  end

  def test_inspect
    vector = Rover::Vector.new(1..10)
    assert_equal "#<Rover::Vector [1, 2, 3, 4, 5, ...]>", vector.inspect
  end

  def test_inspect_string
    vector = Rover::Vector.new(["one", "two", "three", "four", "five", "six", "seven", "eight"])
    assert_equal '#<Rover::Vector ["one", "two", "three", "four", "five", ...]>', vector.inspect
  end

  def test_min
    assert_equal 1, Rover::Vector.new(1..3).min
    assert_equal "a", Rover::Vector.new("a".."c").min
  end

  def test_max
    assert_equal 3, Rover::Vector.new(1..3).max
    assert_equal "c", Rover::Vector.new("a".."c").max
  end

  def test_mean
    assert_equal 2.5, Rover::Vector.new(1..4).mean
  end

  def test_median
    assert_equal 2.5, Rover::Vector.new([1, 2, 3, 10]).median
  end

  def test_percentile
    assert_equal 2.5, Rover::Vector.new([1, 2, 3, 10]).percentile(50)
  end

  def test_sum
    assert_equal 10, Rover::Vector.new(1..4).sum
  end

  # uses Bessel's correction for now since that's all Numo supports
  def test_std
    assert_equal 4, Rover::Vector.new([1, 5, 9]).std
  end

  # uses Bessel's correction for now since that's all Numo supports
  def test_var
    assert_equal 16, Rover::Vector.new([1, 5, 9]).var
  end

  def test_any
    vector = Rover::Vector.new(1..3)
    assert vector.any?
    assert vector.any? { |v| v == 2 }
    assert !vector.any? { |v| v == 4 }
    assert (vector == 2).any?
    assert !(vector == 4).any?
  end

  def test_all
    vector = Rover::Vector.new(1..3)
    assert vector.all? { |v| v < 4 }
    assert !vector.all? { |v| v < 3 }
    assert (vector < 4).all?
    assert !(vector < 3).all?
  end

  def test_empty
    assert_predicate Rover::Vector.new([]), :empty?
    refute_predicate Rover::Vector.new(1..3), :empty?
  end

  def test_map
    vector = Rover::Vector.new([10, 20, 30])
    assert_vector [20, 40, 60], vector.map { |v| v * 2 }
    assert_kind_of Numo::Int64, vector.map { |v| v * 2 }.to_numo
  end

  def test_map_string_to_int
    vector = Rover::Vector.new(["a", "b", "c"])
    assert_vector [1, 1, 1], vector.map { |v| v.size }
    assert_kind_of Numo::Int64, vector.map { |v| v.size }.to_numo
  end

  def test_map_int_to_float
    vector = Rover::Vector.new([10, 20, 30])
    assert_vector [10.5, 20.5, 30.5], vector.map { |v| v + 0.5 }
  end

  def test_map_int_to_string
    vector = Rover::Vector.new([10, 20, 30])
    assert_vector ["10!", "20!", "30!"], vector.map { |v| "#{v}!" }
  end

  def test_map!
    vector = Rover::Vector.new([10, 20, 30])
    assert_equal :int64, vector.type
    vector.map! { |v| "#{v}!" }
    assert_vector ["10!", "20!", "30!"], vector
    assert_equal :object, vector.type
  end

  def test_select
    vector = Rover::Vector.new([10, 20, 30])
    assert_vector [10, 30], vector.select { |v| v != 20 }
  end

  def test_reject
    vector = Rover::Vector.new([10, 20, 30])
    assert_vector [10, 30], vector.reject { |v| v == 20 }
  end

  def test_zip
    a = Rover::Vector.new([1, 2, 3])
    b = Rover::Vector.new(["a", "b", "c"])
    assert_equal [[1, "a"], [2, "b"], [3, "c"]], a.zip(b)
  end

  def test_abs
    assert_vector [2, 1, 0, 1, 2], Rover::Vector.new(-2..2).abs
    assert_raises(NoMethodError) do
      Rover::Vector.new("a".."c").abs
    end
  end

  def test_round
    assert_vector [2, 5, 7], Rover::Vector.new([2.3, 4.5, 6.7]).round, type: :float64
    assert_vector [2, 5, 7], Rover::Vector.new([2, 5, 7]).round, type: :int64
    assert_vector [1.2, 4.6, 7.9], Rover::Vector.new([1.23, 4.56, 7.89]).round(1), type: :float64
    assert_vector [20, 50, 70], Rover::Vector.new([23, 45, 67]).round(-1), type: :int64
  end

  def test_ceil
    assert_vector [1, 3, 5], Rover::Vector.new([0.1, 2.3, 4.5]).ceil, type: :float64
    assert_vector [1, 3, 5], Rover::Vector.new([1, 3, 5]).ceil, type: :int64
    assert_vector [1.3, 4.6, 7.9], Rover::Vector.new([1.23, 4.56, 7.89]).ceil(1), type: :float64
    assert_vector [30, 50, 70], Rover::Vector.new([23, 45, 67]).ceil(-1), type: :int64
  end

  def test_floor
    assert_vector [9, 7, 5], Rover::Vector.new([9.8, 7.6, 5.4]).floor, type: :float64
    assert_vector [9, 7, 5], Rover::Vector.new([9, 7, 5]).floor, type: :int64
    assert_vector [1.2, 4.5, 7.8], Rover::Vector.new([1.23, 4.56, 7.89]).floor(1), type: :float64
    assert_vector [20, 40, 60], Rover::Vector.new([23, 45, 67]).floor(-1), type: :int64
  end

  def test_sqrt
    assert_vector_in_delta [1, 2, 3], Rover::Vector.new([1, 4, 9]).sqrt, type: :float64
    assert_vector_in_delta [1, 2, 3], Rover::Vector.new([1, 4, 9], type: :float64).sqrt, type: :float64
    assert_vector_in_delta [1, 2, 3], Rover::Vector.new([1, 4, 9], type: :float32).sqrt, type: :float32
  end

  def test_cbrt
    assert_vector_in_delta [1, 2, 3], Rover::Vector.new([1, 8, 27]).cbrt, type: :float64
    assert_vector_in_delta [1, 2, 3], Rover::Vector.new([1, 8, 27], type: :float64).cbrt, type: :float64
    assert_vector_in_delta [1, 2, 3], Rover::Vector.new([1, 8, 27], type: :float32).cbrt, type: :float32
  end

  def test_sin
    assert_vector_in_delta [0, 1, 0], Rover::Vector.new([0, Math::PI / 2, Math::PI]).sin, type: :float64
  end

  def test_cos
    assert_vector_in_delta [1, 0, -1], Rover::Vector.new([0, Math::PI / 2, Math::PI]).cos, type: :float64
  end

  def test_tan
    assert_vector_in_delta [0, 1], Rover::Vector.new([0, Math::PI / 4]).tan, type: :float64
  end

  def test_asin
    assert_vector_in_delta [0, Math::PI / 2], Rover::Vector.new([0, 1]).asin, type: :float64
  end

  def test_acos
    assert_vector_in_delta [0, Math::PI / 2, Math::PI], Rover::Vector.new([1, 0, -1]).acos, type: :float64
  end

  def test_atan
    assert_vector_in_delta [0, Math::PI / 4], Rover::Vector.new([0, 1]).atan, type: :float64
  end

  def test_ln
    assert_vector_in_delta [0, 1], Rover::Vector.new([1, Math::E]).ln, type: :float64
    assert_vector_in_delta [0, 1], Rover::Vector.new([1, Math::E], type: :float32).ln, type: :float32
  end

  def test_log
    assert_vector_in_delta [0, 1], Rover::Vector.new([1, Math::E]).log, type: :float64
    assert_vector_in_delta [0, 1], Rover::Vector.new([1, Math::E], type: :float32).log, type: :float32
    assert_vector_in_delta [0, 1], Rover::Vector.new([1, 10]).log(10), type: :float64
    assert_vector_in_delta [0, 1], Rover::Vector.new([1, 10], type: :float32).log(10), type: :float32
    assert_vector_in_delta [0, 1, 2, 3], Rover::Vector.new([1, 2, 4, 8]).log(2), type: :float64
    assert_vector_in_delta [0, 1, 2, 3], Rover::Vector.new([1, 2, 4, 8], type: :float32).log(2), type: :float32
  end

  def test_log10
    assert_vector_in_delta [0, 1], Rover::Vector.new([1, 10]).log10, type: :float64
  end

  def test_log2
    assert_vector_in_delta [0, 1, 2, 3], Rover::Vector.new([1, 2, 4, 8]).log2, type: :float64
  end

  def test_exp
    assert_vector_in_delta [1, Math::E], Rover::Vector.new([0, 1]).exp, type: :float64
  end

  def test_exp2
    assert_vector_in_delta [1, 2, 4, 8], Rover::Vector.new([0, 1, 2, 3]).exp2, type: :float64
  end

  def test_erf
    assert_vector_in_delta [0, 1], Rover::Vector.new([0, 3]).erf, type: :float64
  end

  def test_erfc
    assert_vector_in_delta [1, 0], Rover::Vector.new([0, 3]).erfc, type: :float64
  end

  def test_hypot
    a = Rover::Vector.new([3])
    b = Rover::Vector.new([4])
    assert_vector_in_delta [5], a.hypot(4), type: :float64
    assert_vector_in_delta [5], a.hypot(b), type: :float64
  end

  def test_frexp
    fraction, exponent = Rover::Vector.new([1, 2, 3]).frexp
    assert_vector_in_delta [0.5, 0.5, 0.75], fraction, type: :float64
    assert_vector [1, 2, 2], exponent, type: :int32
  end

  def test_ldexp
    fraction = Rover::Vector.new([0.5, 0.5, 0.75])
    exponent = Rover::Vector.new([1, 2, 2])
    assert_vector_in_delta [1, 2, 3], fraction.ldexp(exponent), type: :float64
  end

  def test_comparison
    vector = Rover::Vector.new(1..3)
    assert_vector [false, true, false], vector == 2
    assert_vector [true, false, true], vector != 2
    assert_vector [false, false, true], vector > 2
    assert_vector [false, true, true], vector >= 2
    assert_vector [true, false, false], vector < 2
    assert_vector [true, true, false], vector <= 2
  end

  def test_equal_big_decimal
    vector = Rover::Vector.new(1..3).map { |v| BigDecimal(v) }
    vector == vector
  end

  def test_string
    assert_vector ["one", "two", "three"], Rover::Vector.new(["one", "two", "three"])
  end

  def test_not
    assert_vector [false, true, false], !Rover::Vector.new([true, false, true])
  end

  def test_nan
    vector = Rover::Vector.new([1, nil, 3])
    assert vector[1].nan?
  end

  def test_diff
    diff = Rover::Vector.new([1, 4, 9]).diff
    assert_equal 3, diff.size
    assert diff[0].nan?
    assert_equal 3, diff[1]
    assert_equal 5, diff[2]
  end

  def test_in
    vector = Rover::Vector.new(1..3)
    assert_vector [false, false, false], vector.in?([])
    assert_vector [true, false, true], vector.in?([1, 3])
  end

  def test_in_string_nil
    vector = Rover::Vector.new(["one", "two", "three"])
    assert_vector [false, false, false], vector.in?([])
    assert_vector [true, false, true], vector.in?(["one", "three", nil])
  end

  def test_in_range
    vector = Rover::Vector.new([1, 2, 3])
    assert_vector [true, true, false], vector.in?(1..2)
  end

  def test_negation
    vector = Rover::Vector.new([-2, 0, 2])
    assert_vector [2, 0, -2], -vector
  end

  def test_tally
    vector = Rover::Vector.new(["hi", "hi", "bye"])
    assert_equal ({"hi" => 2, "bye" => 1}), vector.tally
  end

  def test_clamp!
    vector = Rover::Vector.new([-100, 0, 100])
    vector.clamp!(-5, 5)
    assert_vector [-5, 0, 5], vector
  end

  def test_clamp
    vector = Rover::Vector.new([-100, 0, 100])
    assert_vector [-5, 0, 5], vector.clamp(-5, 5)
  end

  def test_uniq
    assert_vector [1, 2], Rover::Vector.new([1, 1, 1, 2, 2]).uniq
    assert_vector [true, false], Rover::Vector.new([true, true, true, false, false]).uniq
  end

  def test_first
    vector = Rover::Vector.new(1..3)
    # TODO return element instead of vector if no argument in 0.4.0
    assert_vector 1..1, vector.first
    assert_vector 1..1, vector.first(1)
    assert_vector 1..2, vector.first(2)
  end

  def test_last
    vector = Rover::Vector.new(1..3)
    # TODO return element instead of vector if no argument in 0.4.0
    assert_vector 3..3, vector.last
    assert_vector 3..3, vector.last(1)
    assert_vector 2..3, vector.last(2)
  end

  def test_last1
    vector = Rover::Vector.new(1..1)
    assert_vector 1..1, vector.last
  end

  def test_short_last
    vector = Rover::Vector.new(1..3)
    assert_vector 1..3, vector.last(4)
  end

  def test_take
    vector = Rover::Vector.new(1..3)
    assert_vector 1..2, vector.take(2)
  end

  def test_take_negative
    error = assert_raises(ArgumentError) do
      Rover::Vector.new(1..3).take(-1)
    end
    assert_equal "attempt to take negative size", error.message
  end

  def test_bad_size
    error = assert_raises(ArgumentError) do
      Rover::Vector.new(Numo::DFloat.new(2, 3).rand)
    end
    assert_equal "Bad size: [2, 3]", error.message
  end

  def test_setter
    vector = Rover::Vector.new(1..3)
    vector[1] = 5
    assert_vector [1, 5, 3], vector
    vector[1..-1] = [7, 8]
    assert_vector [1, 7, 8], vector
  end

  def test_setter_where
    vector = Rover::Vector.new(1..3)
    where = Rover::Vector.new([true, false, true])
    vector[where] = 0
    assert_vector [0, 2, 0], vector
  end

  def test_setter_where_nil
    vector = Rover::Vector.new([1, "bad", 3])
    vector[vector == "bad"] = nil
    assert_vector [1, nil, 3], vector
  end

  def test_setter_where_index
    vector = Rover::Vector.new(1..3)
    vector[[0, 2]] = 5
    assert_vector [5, 2, 5], vector
  end

  def test_where
    vector = Rover::Vector.new(1..3)
    where = Rover::Vector.new([true, false, true])
    assert_vector [1, 3], vector[where]
  end

  def test_each
    vector = Rover::Vector.new(1..3)
    values = []
    vector.each do |value|
      values << value
    end
    assert_equal [1, 2, 3], values
  end

  def test_each_with_index
    array_data = [1,2,3,4,5]
    vector = Rover::Vector.new(array_data)
    vector.each_with_index do |int, index|
      assert_equal int, array_data[index]
    end
  end

  def test_to_invalid
    error = assert_raises(ArgumentError) do
      Rover::Vector.new(1..3).to(:bad)
    end
    assert_equal "Invalid type: bad", error.message
  end

  def test_to_a
    vector = Rover::Vector.new(1..3)
    assert_equal [1, 2, 3], vector.to_a
  end

  def test_to_html
    vector = Rover::Vector.new(1..3)
    assert_match "<table>", vector.to_html
  end

  def test_clone
    vector = Rover::Vector.new(1..3)
    vector2 = vector.clone
    vector[1] = 0
    assert_vector [1, 2, 3], vector2
  end

  def test_dup
    vector = Rover::Vector.new(1..3)
    vector2 = vector.dup
    vector[1] = 0
    assert_vector [1, 2, 3], vector2
  end
end

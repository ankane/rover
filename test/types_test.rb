require_relative "test_helper"

class TypesTest < Minitest::Test
  def test_constructor_vector
    [:bool, :float32, :float64, :int8, :int16, :int32, :int64, :object, :uint8, :uint16, :uint32, :uint64].each do |type|
      assert_equal type, Rover::Vector.new(1..3, type: type).type
    end
  end

  def test_constructor_data_frame
    [:bool, :float32, :float64, :int8, :int16, :int32, :int64, :object, :uint8, :uint16, :uint32, :uint64].each do |type|
      df = Rover::DataFrame.new({"a" => 1..3}, types: {"a" => type})
      assert_equal type, df["a"].type
      assert_equal ({"a" => type}), df.types
    end
  end

  def test_constructor_nil
    [:float, :float32, :float64].each do |type|
      assert Rover::Vector.new([1, nil, 3], type: type)[1].nan?
    end
  end

  def test_constructor_legacy
    assert_equal :int64, Rover::Vector.new(1..3, type: :int).type
    assert_equal :uint64, Rover::Vector.new(1..3, type: :uint).type
    assert_equal :float64, Rover::Vector.new(1..3, type: :float).type
  end

  def test_read_csv
    df = Rover.read_csv("test/support/data.csv", types: {"a" => :int8})
    assert_equal :int8, df["a"].type
  end

  def test_complex64
    error = assert_raises(ArgumentError) do
      Rover::Vector.new(Numo::SComplex.cast([1]))
    end
    assert_equal "Complex types not supported yet", error.message
  end

  def test_complex128
    error = assert_raises(ArgumentError) do
      Rover::Vector.new(Numo::DComplex.cast([1]))
    end
    assert_equal "Complex types not supported yet", error.message
  end

  def test_int_large
    assert_equal :int64, Rover::Vector.new([2**63 - 1]).type
    assert_raises(RangeError) do
      Rover::Vector.new([2**63])
    end
  end

  # an error seems more intuitive
  # but this is same behavior as Numo, NumPy, and Pandas
  def test_int_overflow
    assert_vector [-1], Rover::Vector.new([2**63 - 1]).to(:int32)
  end

  def test_constructor_int_nan
    error = assert_raises do
      Rover::Vector.new([1.5, 2.5, Float::NAN], type: :int)
    end
    assert_equal "float NaN out of range of integer", error.message
  end

  def test_to_int
    vector = Rover::Vector.new([1.5, 2.5, 3.5]).to(:int)
    assert_vector [1, 2, 3], vector
    assert_equal :int64, vector.type
    assert_kind_of Numo::Int64, vector.to(:int64).to_numo
  end

  def test_to_int_nan
    error = assert_raises do
      Rover::Vector.new([1.5, 2.5, Float::NAN]).to(:int)
    end
    assert_equal "float NaN out of range of integer", error.message
  end

  def test_to_int_infinite
    error = assert_raises do
      Rover::Vector.new([1.5, 2.5, Float::INFINITY]).to(:int)
    end
    assert_equal "float Inf out of range of integer", error.message
  end

  def test_to_int_object_nil
    error = assert_raises do
      Rover::Vector.new(["1", "2", nil]).to(:int)
    end
    assert_equal "no implicit conversion from nil to integer", error.message
  end

  def test_to_int_object
    vector = Rover::Vector.new(["1", "2", "3"]).to(:int)
    assert_vector [1, 2, 3], vector
    assert_equal :int64, vector.type
    assert_kind_of Numo::Int64, vector.to_numo
  end

  def test_to_float
    vector = Rover::Vector.new(["1.0", "2.1", nil]).to(:float)
    assert_equal vector[0], 1.0
    assert_equal vector[1], 2.1
    assert_equal vector[2].nan?, true
    assert_equal :float64, vector.type
    assert_kind_of Numo::DFloat, vector.to_numo
  end

  def test_to_bool
    vector = Rover::Vector.new([1, 2, 0]).to(:bool)
    assert_vector [true, true, false], vector
    assert_equal :bool, vector.type
    assert_kind_of Numo::Bit, vector.to_numo
  end

  def test_to_object
    vector = Rover::Vector.new(1..3).to(:object)
    assert_vector [1, 2, 3], vector
    assert_equal :object, vector.type
    assert_kind_of Numo::RObject, vector.to_numo
  end

  def test_to!
    vector = Rover::Vector.new(["1", "2", "3"])
    vector.to!(:int)
    assert_vector [1, 2, 3], vector
    assert_equal :int64, vector.type
    assert_kind_of Numo::Int64, vector.to_numo
  end
end

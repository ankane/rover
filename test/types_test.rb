require_relative "test_helper"

class TypesTest < Minitest::Test
  def test_constructor
    [:bool, :float32, :float, :int8, :int16, :int32, :int, :object].each do |type|
      assert_equal type, Rover::Vector.new(1..3, type: type).type
    end
  end

  def test_constructor_int_nan
    error = assert_raises do
      Rover::Vector.new([1.5, 2.5, Float::NAN], type: :int)
    end
    assert_equal "Cannot convert missing or infinite values to int", error.message
  end

  def test_to_int
    vector = Rover::Vector.new([1.5, 2.5, 3.5]).to(:int)
    assert_vector [1, 2, 3], vector
    assert_equal :int, vector.type
    assert_kind_of Numo::Int64, vector.to(:int).to_numo
  end

  def test_to_int_nan
    error = assert_raises do
      Rover::Vector.new([1.5, 2.5, Float::NAN]).to(:int)
    end
    assert_equal "Cannot convert missing or infinite values to int", error.message
  end

  def test_to_int_infinite
    error = assert_raises do
      Rover::Vector.new([1.5, 2.5, Float::INFINITY]).to(:int)
    end
    assert_equal "Cannot convert missing or infinite values to int", error.message
  end

  def test_to_int_object_nil
    error = assert_raises do
      Rover::Vector.new(["1", "2", nil]).to(:int)
    end
    assert_equal "Cannot convert missing or infinite values to int", error.message
  end

  def test_to_int_object
    vector = Rover::Vector.new(["1", "2", "3"]).to(:int)
    assert_vector [1, 2, 3], vector
    assert_equal :int, vector.type
    assert_kind_of Numo::Int64, vector.to_numo
  end

  def test_to_float
    vector = Rover::Vector.new(["1.0", "2.1", nil]).to(:float)
    assert_equal vector[0], 1.0
    assert_equal vector[1], 2.1
    assert_equal vector[2].nan?, true
    assert_equal :float, vector.type
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
end

require_relative "test_helper"

class JoinTest < Minitest::Test
  def test_inner_join
    df = Rover::DataFrame.new({
      a: [1, 2, 3],
      b: ["one", "two", "three"]
    })

    other_df = Rover::DataFrame.new({
      a: [1, 1, 2],
      c: ["c1", "c2", "c3"]
    })

    expected = Rover::DataFrame.new({
      a: [1, 1, 2],
      b: ["one", "one", "two"],
      c: ["c1", "c2", "c3"]
    })

    assert_equal expected, df.inner_join(other_df)
  end

  def test_inner_join_on_hash
    df = Rover::DataFrame.new({
      a: [1, 2, 3],
      b: ["one", "two", "three"]
    })

    other_df = Rover::DataFrame.new({
      a2: [1, 1, 2],
      c: ["c1", "c2", "c3"]
    })

    expected = Rover::DataFrame.new({
      a: [1, 1, 2],
      b: ["one", "one", "two"],
      a2: [1, 1, 2],
      c: ["c1", "c2", "c3"]
    })

    assert_equal expected, df.inner_join(other_df, on: {a: :a2})
  end

  def test_inner_join_empty
    df = Rover::DataFrame.new({
      a: [1, 2, 3],
      b: ["one", "two", "three"]
    })

    other_df = Rover::DataFrame.new({
      a: [4],
      c: ["c1"]
    })

    result = df.inner_join(other_df)
    assert_equal 0, result.size
    assert_equal [:a, :b, :c], result.keys
  end

  def test_inner_join_nil
    df = Rover::DataFrame.new({
      a: [1, 2, 3],
      b: [nil, nil, nil]
    }, types: {b: :object})

    other_df = Rover::DataFrame.new({
      a: [1, 1, 2]
    })

    expected = Rover::DataFrame.new({
      a: [1, 1, 2],
      b: [nil, nil, nil]
    }, types: {b: :object})

    assert_equal expected, df.inner_join(other_df)
  end

  def test_inner_join_on_bad
    df = Rover::DataFrame.new({
      a: [1, 2, 3],
      b: ["one", "two", "three"]
    })

    error = assert_raises(ArgumentError) do
      df.inner_join(df, on: :bad)
    end
    assert_equal "Missing keys: bad", error.message
  end

  def test_left_join
    df = Rover::DataFrame.new({
      a: [1, 2, 3],
      b: ["one", "two", "three"]
    })

    other_df = Rover::DataFrame.new({
      a: [1, 1, 2],
      c: ["c1", "c2", "c3"]
    })

    expected = Rover::DataFrame.new({
      a: [1, 1, 2, 3],
      b: ["one", "one", "two", "three"],
      c: ["c1", "c2", "c3", nil]
    })

    assert_equal expected, df.left_join(other_df)
  end
end

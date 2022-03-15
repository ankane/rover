require_relative "test_helper"

class PlotTest < Minitest::Test
  def test_defaults
    df = Rover::DataFrame.new({"a" => ["one", "two", "three"], "b" => [1, 2, 3]})
    assert_plot_type "column", df.plot("a", "b")
    assert_plot_type "scatter", df.plot("b", "b")
  end

  def test_default_columns
    df = Rover::DataFrame.new({"a" => ["one", "two", "three"], "b" => [1, 2, 3]})
    assert_plot_type "column", df.plot
  end

  def test_type
    df = Rover::DataFrame.new({"a" => ["one", "two", "three"], "b" => [1, 2, 3]})
    assert_plot_type "pie", df.plot("a", "b", type: "pie")
    assert_plot_type "line", df.plot("a", "b", type: "line")
    assert_plot_type "column", df.plot("a", "b", type: "column")
    assert_plot_type "bar", df.plot("a", "b", type: "bar")
    assert_plot_type "area", df.plot("a", "b", type: "area")
    assert_plot_type "scatter", df.plot("b", "b", type: "scatter")
  end

  def test_group_option
    df = Rover::DataFrame.new({"a" => ["one", "two", "three"], "b" => [1, 2, 3], "c" => ["group1", "group1", "group2"]})
    assert_group df.plot("a", "b", type: "line", group: "c")
    assert_group df.plot("a", "b", type: "column", group: "c")
    assert_group df.plot("a", "b", type: "bar", group: "c")
    assert_group df.plot("a", "b", type: "area", group: "c")
    assert_group df.plot("b", "b", type: "scatter", group: "c")
  end

  def test_group_option_pie
    df = Rover::DataFrame.new({"a" => ["one", "two", "three"], "b" => [1, 2, 3], "c" => ["group1", "group1", "group2"]})
    error = assert_raises(ArgumentError) do
      df.plot("a", "b", type: "pie", group: "c")
    end
    assert_equal "Cannot use group option with pie chart", error.message
  end

  def test_group_method
    df = Rover::DataFrame.new({"a" => ["one", "two", "three"], "b" => [1, 2, 3], "c" => ["group1", "group1", "group2"]})
    assert_group df.group("c").plot("a", "b", type: "line")
    assert_group df.group("c").plot("a", "b", type: "column")
    assert_group df.group("c").plot("a", "b", type: "bar")
    assert_group df.group("c").plot("a", "b", type: "area")
    assert_group df.group("c").plot("b", "b", type: "scatter")
  end

  def test_group_method_multiple_columns
    df = Rover::DataFrame.new({"a" => ["one", "two", "three"], "b" => [1, 2, 3], "c" => ["group1", "group1", "group2"]})
    error = assert_raises(ArgumentError) do
      df.group("c", "c").plot("a", "b")
    end
    assert_equal "Multiple groups not supported", error.message
  end

  def test_group_method_group_option
    df = Rover::DataFrame.new({"a" => ["one", "two", "three"], "b" => [1, 2, 3], "c" => ["group1", "group1", "group2"]})
    error = assert_raises(ArgumentError) do
      df.group("c").plot("a", "b", group: "c")
    end
    assert_equal "unknown keyword: :group", error.message
  end

  def test_type_unknown
    df = Rover::DataFrame.new({"a" => ["one", "two", "three"]})
    error = assert_raises do
      df.plot("a", "a")
    end
    assert_equal "Cannot determine type. Use the type option.", error.message
  end

  def assert_plot_type(expected, plot)
    assert_kind_of Vega::LiteChart, plot

    case expected
    when "column"
      assert_equal "bar", plot.spec[:mark][:type]
    when "pie"
      assert_equal "arc", plot.spec[:mark][:type]
    when "scatter"
      assert_equal "circle", plot.spec[:mark][:type]
    else
      assert_equal expected, plot.spec[:mark][:type]
    end
  end

  def assert_group(plot)
    assert_kind_of Vega::LiteChart, plot
    assert_equal "c", plot.spec[:encoding][:color][:field]
  end
end

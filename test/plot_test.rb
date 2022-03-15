require_relative "test_helper"

class PlotTest < Minitest::Test
  def test_defaults
    df = Rover::DataFrame.new({"a" => ["one", "two", "three"], "b" => [1, 2, 3]})
    assert_plot_type "column", df.plot("a", "b")
    assert_plot_type "scatter", df.plot("b", "b")
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

  def test_multiple_series
    df = Rover::DataFrame.new({"category" => ["A", "A", "A", "B", "B", "B", "C", "C", "C"], 
                              "group" => ["x", "y", "z", "x", "y", "z", "x", "y", "z"],
                              "value" => [0.1, 0.6, 0.9, 0.7, 0.2, 1.1, 0.6, 0.1, 0.2]})

    error = assert_raises do
      df.plot("group", "value", type: "pie", group: "category")
    end
    assert_equal "Cannot use group on type pie.", error.message

    assert_plot_type "line", df.plot("group", "value", type: "line", group: "category")
    assert_plot_type "column", df.plot("group", "value", type: "column", group: "category")
    assert_plot_type "bar", df.plot("group", "value", type: "bar", group: "category")
    assert_plot_type "area", df.plot("group", "value", type: "area", group: "category")

    df = Rover::DataFrame.new({"category" => ["A", "A", "A", "B", "B", "B", "C", "C", "C"], 
                              "group" => [1, 2, 3, 1, 2, 3, 1, 2, 3],
                              "value" => [0.1, 0.6, 0.9, 0.7, 0.2, 1.1, 0.6, 0.1, 0.2]})
    assert_plot_type "scatter", df.plot("group", "value", type: "scatter", group: "category")
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
end

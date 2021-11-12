# Rover

Simple, powerful data frames for Ruby

:mountain: Designed for data exploration and machine learning, and powered by [Numo](https://github.com/ruby-numo/numo-narray)

:evergreen_tree: Uses [Vega](https://github.com/ankane/vega) for visualization

[![Build Status](https://github.com/ankane/rover/workflows/build/badge.svg?branch=master)](https://github.com/ankane/rover/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'rover-df'
```

## Intro

A data frame is an in-memory table. It’s a useful data structure for data analysis and machine learning. It uses columnar storage for fast operations on columns.

Try it out for forecasting by clicking the button below (it can take a few minutes to start):

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/ankane/ml-stack/master?filepath=Forecasting.ipynb)

Use the `Run` button (or `SHIFT` + `ENTER`) to run each line.

## Creating Data Frames

From an array

```ruby
Rover::DataFrame.new([
  {a: 1, b: "one"},
  {a: 2, b: "two"},
  {a: 3, b: "three"}
])
```

From a hash

```ruby
Rover::DataFrame.new({
  a: [1, 2, 3],
  b: ["one", "two", "three"]
})
```

From Active Record

```ruby
Rover::DataFrame.new(User.all)
```

From a CSV

```ruby
Rover.read_csv("file.csv")
# or
Rover.parse_csv("CSV,data,string")
```

From Parquet (requires the [red-parquet](https://github.com/apache/arrow/tree/master/ruby/red-parquet) gem)

```ruby
Rover.read_parquet("file.parquet")
# or
Rover.parse_parquet("PAR1...")
```

## Attributes

Get number of rows

```ruby
df.count
```

Get column names

```ruby
df.keys
```

Check if a column exists

```ruby
df.include?(name)
```

## Selecting Data

Select a column

```ruby
df[:a]
```

> Note that strings and symbols are different keys, just like hashes. Creating a data frame from Active Record, a CSV, or Parquet uses strings.

Select multiple columns

```ruby
df[[:a, :b]]
```

Select first rows

```ruby
df.head
# or
df.first(5)
```

Select last rows

```ruby
df.tail
# or
df.last(5)
```

Select rows by index

```ruby
df[1]
# or
df[1..3]
# or
df[[1, 4, 5]]
```

Iterate over rows

```ruby
df.each_row { |row| ... }
```

Iterate over a column

```ruby
df[:a].each { |item| ... }
# or
df[:a].each_with_index { |item, index| ... }
```

## Filtering

Filter on a condition

```ruby
df[df[:a] == 100]
df[df[:a] != 100]
df[df[:a] > 100]
df[df[:a] >= 100]
df[df[:a] < 100]
df[df[:a] <= 100]
```

In

```ruby
df[df[:a].in?([1, 2, 3])]
df[df[:a].in?(1..3)]
df[df[:a].in?(["a", "b", "c"])]
```

Not in

```ruby
df[!df[:a].in?([1, 2, 3])]
```

And, or, and exclusive or

```ruby
df[(df[:a] > 100) & (df[:b] == "one")] # and
df[(df[:a] > 100) | (df[:b] == "one")] # or
df[(df[:a] > 100) ^ (df[:b] == "one")] # xor
```

## Operations

Basic operations

```ruby
df[:a] + 5
df[:a] - 5
df[:a] * 5
df[:a] / 5
df[:a] % 5
df[:a] ** 2
```

Summary statistics

```ruby
df[:a].count
df[:a].sum
df[:a].mean
df[:a].median
df[:a].percentile(90)
df[:a].min
df[:a].max
df[:a].std
df[:a].var
```

Count occurrences

```ruby
df[:a].tally
```

Cross tabulation

```ruby
df[:a].crosstab(df[:b])
```

## Grouping

Group

```ruby
df.group(:a).count
```

Works with all summary statistics

```ruby
df.group(:a).max(:b)
```

Multiple groups

```ruby
df.group([:a, :b]).count
```

## Ranking

Rank return a vector describing each vector element's rank compared to the other elements (ties get the same rank but increment the next ranked item's rank)

```ruby
df[:a].rank
# same as df[:a].rank(direction="asc")
```
Default ranking is in ascending order, where higher numbers are considered better (lower) rank. Example: "number of widgets sold", where a higher number is "better".

Rank in desdending order, where lower numbers are considered better (lower) rank. Example: "number of widgets returned by customer", where a lower number is "better".

```ruby
df[:a].rank(direction="desc")
```

TO DO: consider allowing any datatype that is comparable (has <=> implemented). Currently does not work on vectors of Strings, although in principle it could. Awaiting a use-case.

## Best_In, Worst_In
Considering the last element of a ranked vector, this returns the number of elements it is consecutively better than until it meets a better ranked element. 

```ruby
df[:a].best_in
# same as df[:a].best_in(direction="asc")
```

returns 0 if it isn't the better than its previous value or it exhaust previous values in the vector

This answers the question, "the best value in N periods". Given a vector of 13 weeks of sales, and the last value has a rank of 2, then this returns how many weeks back from that one has to go to find a better value (here, of rank 1)

As you might expect, you can specify a direction for the ranking to be used by best_in:

```ruby
df[:a].best_in(direction="desc")
```

Sometimes you want to know if it's the worst value in some number of periods:

```ruby
df[:a].worst_in
```

This and its variants are the complement to the best_in() method. 

TO DO: allow user to specify which value to start looking back from, rather than only the last one. Awaiting a use-case.

## Visualization

Add [Vega](https://github.com/ankane/vega) to your application’s Gemfile:

```ruby
gem 'vega'
```

And use:

```ruby
df.plot(:a, :b)
```

Specify the chart type (`line`, `pie`, `column`, `bar`, `area`, or `scatter`)

```ruby
df.plot(:a, :b, type: "pie")
```

## Updating Data

Add a new column

```ruby
df[:a] = 1
# or
df[:a] = [1, 2, 3]
```

Update a single element

```ruby
df[:a][0] = 100
```

Update multiple elements

```ruby
df[:a][0..2] = 1
# or
df[:a][0..2] = [1, 2, 3]
```

Update all elements

```ruby
df[:a] = df[:a].map { |v| v.gsub("a", "b") }
# or
df[:a].map! { |v| v.gsub("a", "b") }
```

Update elements matching a condition

```ruby
df[:a][df[:a] > 100] = 0
```

Clamp

```ruby
df[:a].clamp!(0, 100)
```

Delete columns

```ruby
df.delete(:a)
# or
df.except!(:a, :b)
```

Rename a column

```ruby
df[:new_a] = df.delete(:a)
```

Sort rows

```ruby
df.sort_by! { |r| r[:a] }
```

Clear all data

```ruby
df.clear
```

## Combining Data Frames

Add rows

```ruby
df.concat(other_df)
```

Add columns

```ruby
df.merge!(other_df)
```

Inner join

```ruby
df.inner_join(other_df)
# or
df.inner_join(other_df, on: :a)
# or
df.inner_join(other_df, on: [:a, :b])
# or
df.inner_join(other_df, on: {df_col: :other_df_col})
```

Left join

```ruby
df.left_join(other_df)
```

## Encoding

One-hot encoding

```ruby
df.one_hot
```

Drop a variable in each category to avoid the dummy variable trap

```ruby
df.one_hot(drop: true)
```

## Conversion

Array of hashes

```ruby
df.to_a
```

Hash of arrays

```ruby
df.to_h
```

Numo array

```ruby
df.to_numo
```

CSV

```ruby
df.to_csv
```

Parquet (requires the [red-parquet](https://github.com/apache/arrow/tree/master/ruby/red-parquet) gem)

```ruby
df.to_parquet
```

## Types

You can specify column types when creating a data frame

```ruby
Rover::DataFrame.new(data, types: {"a" => :int, "b" => :float})
```

Or

```ruby
Rover.read_csv("data.csv", types: {"a" => :int, "b" => :float})
```

Supported types are:

- boolean - `bool`
- float - `float`, `float32`
- integer - `int`, `int32`, `int16`, `int8`
- unsigned integer - `uint`, `uint32`, `uint16`, `uint8`
- object - `object`

Get column types

```ruby
df.types
```

For a specific column

```ruby
df[:a].type
```

Change the type of a column

```ruby
df[:a] = df[:a].to(:int)
```

## History

View the [changelog](https://github.com/ankane/rover/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/rover/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/rover/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/rover.git
cd rover
bundle install
bundle exec rake test
```

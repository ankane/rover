# Rover

Simple, powerful data frames for Ruby

:mountain: Designed for data exploration and machine learning, and powered by [Numo](https://github.com/ruby-numo/numo-narray) for blazing performance

[![Build Status](https://travis-ci.org/ankane/rover.svg?branch=master)](https://travis-ci.org/ankane/rover)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'rover-df'
```

## Intro

A data frame is an in-memory table. It’s a useful data structure for data analysis and machine learning. It uses columnar storage for fast operations on columns.

Try it out for forecasting by clicking the button below:

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

> Note that strings and symbols are different keys, just like hashes

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

## Filtering

Filter on a condition

```ruby
df[df[:a] > 100]
```

And

```ruby
df[df[:a] > 100 & df[:b] == "one"]
```

Or

```ruby
df[df[:a] > 100 | df[:b] == "one"]
```

Not

```ruby
df[df[:a] != 100]
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
```

Cross tabulation

```ruby
df[:a].crosstab(df[:b])
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

## 0.2.7 (unreleased)

- Added support for booleans to Parquet methods
- Added support for creating data frames from `ActiveRecord::Result`
- Added `types` option to `read_parquet` and `parse_parquet` methods

## 0.2.6 (2021-10-27)

- Added support for `nil` headers to `read_csv` and `parse_csv`
- Added `read_parquet`, `parse_parquet`, and `to_parquet` methods

## 0.2.5 (2021-09-25)

- Fixed column types with joins

## 0.2.4 (2021-06-03)

- Added grouping for `std` and `var`
- Fixed `==` for data frames
- Fixed error with `first` and `last` for data frames
- Fixed error with `last` when vector size is smaller than `n`

## 0.2.3 (2021-02-08)

- Added `select`, `reject`, and `map!` methods to vectors

## 0.2.2 (2021-01-01)

- Added line, pie, area, and bar charts
- Added `|` and `^` for vectors
- Fixed typecasting with `map`

## 0.2.1 (2020-11-23)

- Added `plot` method to data frames
- Improved error message when too few headers

## 0.2.0 (2020-08-17)

- Added `numeric?` and `zip` methods to vectors
- Changed group calculations to return a data frame instead of a hash
- Changed `each_row` to return enumerator
- Improved inspect
- Fixed `any?`, `all?`, and `uniq` for boolean vectors

## 0.1.1 (2020-06-10)

- Added methods and options for types
- Added grouping
- Added one-hot encoding
- Added `sample` to data frames
- Added `tally`, `var`, `std`, `take`, `count`, and `length` to vectors
- Improved error message for `read_csv` with no headers

## 0.1.0 (2020-05-13)

- First release

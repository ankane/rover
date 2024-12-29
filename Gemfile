source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest", ">= 5"
gem "activerecord"
gem "activesupport"
gem "sqlite3"
gem "iruby", require: false
gem "vega"
gem "csv"

# do not install by default
# since it tries to install arrow
# with apt/homebrew install
gem "red-parquet" if ENV["TEST_PARQUET"]

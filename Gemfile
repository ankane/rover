source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest", ">= 5"
gem "activerecord", ">= 5"
gem "activesupport", ">= 5"
gem "sqlite3", "< 2"
gem "iruby", require: false
gem "vega"
gem "csv"

# do not install by default
# since it tries to install arrow
# with apt/homebrew install
gem "red-parquet" if ENV["TEST_PARQUET"]

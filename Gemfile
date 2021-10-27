source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest", ">= 5"
gem "activerecord", ">= 5"
gem "sqlite3"
gem "iruby", require: false
gem "vega"

# do not install by default
# since it tries to install arrow
gem "red-parquet" if ENV["TEST_PARQUET"]

require_relative "lib/rover/version"

Gem::Specification.new do |spec|
  spec.name          = "rover-df"
  spec.version       = Rover::VERSION
  spec.summary       = "Simple, powerful data frames for Ruby"
  spec.homepage      = "https://github.com/ankane/rover"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "numo-narray", ">= 0.9.1.9"
end

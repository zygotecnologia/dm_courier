lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dm_courier/version"

Gem::Specification.new do |spec|
  spec.name          = "dm_courier"
  spec.version       = DMCourier::VERSION.dup
  spec.authors       = ["Jaison Erick", "João Paulo Lethier"]
  spec.email         = ["jaisonreis@gmail.com", 'jplethier@gmail.com']

  spec.summary       = "A delivery method that abstract the most common email delivery APIs"
  spec.description   = "A delivery method that abstract the most common email delivery APIs"
  spec.homepage      = "http://github.com/sumoners/dm_courier"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`
                       .split("\x0")
                       .reject { |f| f.match(%r{^(test|spec|features)/}) }

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4.0"
  spec.required_rubygems_version = ">= 2.4.5"

  # spec.add_dependency "mandrill-api", "~> 1.0.53"
  spec.add_dependency "simple_spark", "~> 1.0.2"
  spec.add_dependency "sendgrid-ruby", "~> 1.1.6"
  spec.add_dependency "http", "0.9.8"

  spec.add_development_dependency "codeclimate-test-reporter", "~> 0.5"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "mail", "~> 2.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "simplecov", "~> 0.11"
  spec.add_development_dependency "rubocop", "~> 0.36"
  spec.add_development_dependency "pry"
end

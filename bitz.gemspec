# frozen_string_literal: true

$: << File.expand_path("lib")

require_relative "lib/bitz"

Gem::Specification.new do |spec|
  spec.name = "bitz"
  spec.version = Bitz::VERSION
  spec.authors = ["Aaron Patterson"]
  spec.email = "tenderlove@ruby-lang.org"

  spec.summary = "A pure Ruby, JIT-friendly dynamic bitset implementation"
  spec.description = "Bitz provides a dynamic bitset implementation for Ruby with efficient bit manipulation operations, automatic buffer resizing, and idiomatic operators."
  spec.homepage = "https://github.com/tenderlove/bitz"
  spec.license = "Apache-2.0"

  spec.files       = `git ls-files -z`.split("\x0")
  spec.test_files  = spec.files.grep(%r{^test/})

  spec.required_ruby_version = ">= 3.0.0"
  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end

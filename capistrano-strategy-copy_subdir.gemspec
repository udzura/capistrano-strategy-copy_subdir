# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano-strategy-copy_subdir'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-strategy-copy_subdir"
  spec.version       = Capistrano::Deploy::Strategy::CopySubdir::VERSION
  spec.authors       = ["Uchio KONDO", "Hidenori DOI"]
  spec.email         = ["udzura@udzura.jp"]
  spec.description   = %q{Introduce Capistrano::Deploy::Strategy::CopySubdir}
  spec.summary       = %q{Introduce Capistrano::Deploy::Strategy::CopySubdir}
  spec.homepage      = "https://github.com/udzura/capistrano-strategy-copy_subdir"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "capistrano", "~> 2.13.0"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end

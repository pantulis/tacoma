require "bundler/setup"

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tacoma/version'

Gem::Specification.new do |spec|
  spec.name          = "tacoma"
  spec.version       = Tacoma::VERSION
  spec.authors       = ["Juan Lupión"]
  spec.email         = ["pantulis@gmail.com"]
  spec.description   = %q{Easy command line tool for AWS credentials management}
  spec.summary       = "This tool reads a YAML file with the credentials for your AWS accounts and loads them into  your environment."
  spec.homepage      = "https://github.com/pantulis/tacoma"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($\)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  
  spec.add_runtime_dependency 'thor', '~> 0'
  spec.add_development_dependency "minitest", '~> 0'
  spec.add_development_dependency "bundler", '~> 0'
  spec.add_development_dependency "rake", '~> 0'
end

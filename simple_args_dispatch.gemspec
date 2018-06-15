# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "simple_args_dispatch/version"

Gem::Specification.new do |spec|
  spec.name          = "simple_args_dispatch"
  spec.version       = SimpleArgsDispatch::VERSION
  spec.authors       = ["R"]
  spec.email         = ["raphy@hobbitton.at"]

  spec.summary       = %q{ Ruby utility to eaily parse command line arguments with optional use of YAML template files }
  #spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/raphyduck/simple_args_dispatch"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_runtime_dependency 'simple_speaker', '~> 0.3.0'
end


lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "heavylog/version"

Gem::Specification.new do |spec|
  spec.name          = "heavylog"
  spec.version       = Heavylog::VERSION
  spec.authors       = ["Kristjan Rang"]
  spec.email         = ["mail@rang.ee"]

  spec.summary       = "Format all Rails logging per request"
  spec.description   = "Format all Rails logging per request"
  spec.homepage      = "https://github.com/krisrang/heavylog"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency 'activesupport', '>= 5'
  spec.add_runtime_dependency 'actionpack',    '>= 5'
  spec.add_runtime_dependency 'railties',      '>= 5'
  spec.add_runtime_dependency 'request_store', '~> 1.4'
end

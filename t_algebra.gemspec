require_relative "lib/t_algebra/version"

Gem::Specification.new do |spec|
  spec.name = "t_algebra"
  spec.version = TAlgebra::VERSION
  spec.authors = ["aaron"]
  spec.email = ["afg419@gmail.com"]

  spec.summary = "Functor, Applicative, and Monad interfaces for Ruby"
  spec.homepage = "https://github.com/afg419/t_algebra"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/afg419/t_algebra"
  spec.metadata["changelog_uri"] = "https://example.com"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end

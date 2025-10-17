# frozen_string_literal: true

require_relative "lib/reducto_ai/version"

Gem::Specification.new do |spec|
  spec.name = "reducto_ai"
  spec.version = ReductoAI::VERSION
  spec.authors = ["dpaluy"]
  spec.email = ["dpaluy@users.noreply.github.com"]

  spec.summary = "Ruby client for the Reducto document intelligence API."
  spec.description = "ReductoAI provides a lightweight Faraday-based wrapper for Reducto's Parse, Split, Extract, " \
                     "Edit, and Pipeline endpoints including async helpers and Rails-friendly configuration."
  spec.homepage = "https://github.com/dpaluy/reducto_ai"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/dpaluy/reducto_ai"
  spec.metadata["changelog_uri"] = "https://github.com/dpaluy/reducto_ai/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.9"
  spec.add_dependency "faraday-multipart", "~> 1.0"
end

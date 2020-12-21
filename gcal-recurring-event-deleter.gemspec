require_relative 'lib/app/version'

Gem::Specification.new do |spec|
  spec.name          = "gcal-recurring-event-deleter"
  spec.version       = Gcal::Recurring::Event::Deleter::VERSION
  spec.authors       = ["Juan Li Puma"]
  spec.email         = ["juanlipuma94@gmail.com"]

  spec.summary       = %q{CLI tool for deleting a range of occurrences of a recurring event in Google Calendar.}
  spec.description   = %q{CLI tool that allows selecting a calendar, a recurring event from within said calendar, a date range, and deletes all occurrences of a recurring event betwewn those dates..}
  spec.homepage      = "https://github.com/lipusal/gcal-recurring-event-deleter"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end

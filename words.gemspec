# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{words}
  s.version = "0.4.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Roja Buck"]
  s.date = %q{2010-06-20}
  s.default_executable = %q{build_wordnet}
  s.description = %q{Words, with both pure ruby & tokyo-cabinate backends, implements a fast interface to Wordnet® over the same easy-to-use API. The FFI backend makes use of Tokyo Cabinet and the FFI interface, rufus-tokyo, to provide cross ruby distribution compatability and blistering speed. The pure ruby interface operates on a special ruby optimised index along with the basic dictionary files provided by WordNet®. I have attempted to provide ease of use in the form of a simple yet powerful api and installation is a sintch!}
  s.email = %q{roja@arbia.co.uk}
  s.executables = ["build_wordnet"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README.markdown",
     "Rakefile",
     "VERSION",
     "bin/build_wordnet",
     "examples.rb",
     "lib/evocations.rb",
     "lib/homographs.rb",
     "lib/relation.rb",
     "lib/synset.rb",
     "lib/wordnet_connectors/pure_wordnet_connection.rb",
     "lib/wordnet_connectors/tokyo_wordnet_connection.rb",
     "lib/words.rb",
     "spec/words_spec.rb",
     "words.gemspec"
  ]
  s.homepage = %q{http://github.com/roja/words}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{words}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{A Fast & Easy to use interface to WordNet® with cross ruby distribution compatability.}
  s.test_files = [
    "spec/words_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
  end
end


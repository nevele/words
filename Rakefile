require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "words"
    gem.summary = %Q{A fast, easy to use interface to WordNet® with cross ruby distribution compatability.}
    gem.description = %Q{A fast, easy to use interface to WordNet® with cross ruby distribution compatability. We use TokyoCabinet to store the dataset and the excellent rufus-tokyo to interface with it. This allows us to have full compatability across ruby distributions while still remaining both fast and simple to use.}
    gem.email = "roja@arbia.co.uk"
    gem.homepage = "http://github.com/roja/words"
    gem.authors = ["Roja Buck"]
    gem.add_development_dependency "trollop", ">= 1.15"
    gem.add_dependency 'rufus-tokyo', '>= 1.0.5'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "words #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
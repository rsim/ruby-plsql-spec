require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ruby-plsql-spec"
    gem.summary = "Oracle PL/SQL unit testing framework using Ruby and RSpec"
    gem.description = <<-EOS
ruby-plsql-spec is Oracle PL/SQL unit testing framework which is built using Ruby programming language, ruby-plsql library and RSpec testing framework.
EOS
    gem.email = "raimonds.simanovskis@gmail.com"
    gem.homepage = "http://github.com/rsim/ruby-plsql-spec"
    gem.authors = ["Raimonds Simanovskis"]
    gem.add_dependency "ruby-plsql", ">= 0.4.3"
    gem.add_dependency "thor", ">= 0.14.2"
    gem.add_dependency "rspec", "~> 2.0.1"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/plsql/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |t|
  t.rcov = true
  t.rcov_opts =  ['--exclude', '/Library,spec/']
  t.pattern = 'spec/plsql/**/*_spec.rb'
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'doc'
  rdoc.title = "ruby-plsql-spec #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

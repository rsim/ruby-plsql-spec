require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'

begin
  require 'juwelier'
  Juwelier::Tasks.new do |gem|
    gem.name = "ruby-plsql-spec"
    gem.summary = "Oracle PL/SQL unit testing framework using Ruby and RSpec"
    gem.description = <<-EOS
ruby-plsql-spec is Oracle PL/SQL unit testing framework which is built using Ruby programming language, ruby-plsql library and RSpec testing framework.
  EOS
    gem.email = "raimonds.simanovskis@gmail.com"
    gem.homepage = "http://github.com/rsim/ruby-plsql-spec"
    gem.license = "MIT"
    gem.authors = ["Raimonds Simanovskis"]
  end
  Juwelier::RubygemsDotOrgTasks.new
rescue LoadError
  # juwelier not installed
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

task :default => :spec
task :test => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'doc'
  rdoc.title = "ruby-plsql-spec #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

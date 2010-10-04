require "rubygems"
require "spec"
gem "ruby-plsql", ">= 0.4.3"
require "ruby-plsql"


# Establish connection to database where tests will be performed.
# Change according to your needs.
DATABASE_USER = "hr"
DATABASE_PASSWORD = "hr"
DATABASE_NAME = "orcl"
DATABASE_HOST = "localhost"
DATABASE_PORT = 1521

plsql.connect! DATABASE_USER, DATABASE_PASSWORD, :host => DATABASE_HOST, :port => DATABASE_PORT, :database => DATABASE_NAME
# plsql.connect! "APPS", "APPS", "VIS"

# Set autocommit to false so that automatic commits after each statement are _not_ performed
plsql.connection.autocommit = false
# reduce network traffic in case of large resultsets
plsql.connection.prefetch_rows = 100
# uncomment to log DBMS_OUTPUT to standard output
# plsql.dbms_output_stream = STDOUT

# uncomment to log code coverage using DBMS_PROFILER
# PLSQL_COVERAGE = true

PLSQL_COVERAGE = ENV['COVERAGE'] && true unless defined?(PLSQL_COVERAGE)
if PLSQL_COVERAGE
  require File.expand_path('../support/plsql_coverage', __FILE__)
  PLSQL::Coverage.start
end

# Do logoff when exiting to ensure that session temporary tables
# (used when calling procedures with table types defined in packages)
at_exit do
  if PLSQL_COVERAGE
    PLSQL::Coverage.stop
    coverage_directory = File.expand_path('../../coverage', __FILE__)
    PLSQL::Coverage.report :directory => coverage_directory
  end

  plsql.logoff
end

Spec::Runner.configure do |config|
  config.before(:each) do
    plsql.savepoint "before_each"
  end
  config.after(:each) do
    # Always perform rollback to savepoint after each test
    plsql.rollback_to "before_each"
  end
  config.after(:all) do
    # Always perform rollback after each describe block
    plsql.rollback
  end
end

# require all helper methods which are located in any helpers subdirectories
Dir[File.dirname(__FILE__) + '/**/helpers/*.rb'].each {|f| require f}

# require all factory modules which are located in any factories subdirectories
Dir[File.dirname(__FILE__) + '/**/factories/*.rb'].each {|f| require f}

# Add source directory to load path where PL/SQL example procedures are defined.
# It is not required if PL/SQL procedures are already loaded in test database in some other way.
$:.push File.dirname(__FILE__) + '/../source'


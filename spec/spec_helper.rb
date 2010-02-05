require "rubygems"
require "spec"
require "ruby-plsql"

# Establish connection to database where tests will be performed.
# Change according to your needs.
DATABASE_USER = "hr"
DATABASE_PASSWORD = "hr"
DATABASE_NAME = "orcl"
DATABASE_HOST = "localhost" # necessary for JDBC connection
DATABASE_PORT = 1521        # necessary for JDBC connection

unless defined?(JRUBY_VERSION)
  plsql.connection = OCI8.new DATABASE_USER, DATABASE_PASSWORD, DATABASE_NAME
else
  plsql.connection = java.sql.DriverManager.getConnection("jdbc:oracle:thin:@#{DATABASE_HOST}:#{DATABASE_PORT}:#{DATABASE_NAME}",
    DATABASE_USER, DATABASE_PASSWORD)
end

# Set autocommit to false so that automatic commits after each statement are _not_ performed
plsql.connection.autocommit = false
# reduce network traffic in case of large resultsets
plsql.connection.prefetch_rows = 100
# uncomment to log DBMS_OUTPUT to standard output
# plsql.dbms_output_stream = STDOUT

# Do logoff when exiting to ensure that session temporary tables
# (used when calling procedures with table types defined in packages)
at_exit do
  plsql.logoff
end

Spec::Runner.configure do |config|
  config.before(:each) do
    plsql.execute "SAVEPOINT before_each"
  end
  config.after(:each) do
    # Always perform rollback to savepoint after each test
    plsql.execute "ROLLBACK TO before_each"
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


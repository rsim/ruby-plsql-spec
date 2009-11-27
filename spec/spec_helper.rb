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

Spec::Runner.configure do |config|
  config.after(:each) do
    # Always perform rollback after each test
    plsql.rollback
  end
end

# As ruby-plsql returns NUMBER values as BigDecimal values in Ruby then
# change format how they are by default displayed
BigDecimal.class_eval do
  def inspect
    to_s('F')
  end
end

# As ruby-plsql returns NULL as Ruby nil then change nil.inspect to return 'NULL'
NilClass.class_eval do
  def inspect
    'NULL'
  end
end

# require all factory modules
Dir[File.dirname(__FILE__) + '/factories/*.rb'].each {|f| require f}

# Add source directory to load path where PL/SQL example procedures are defined.
# It is not required if PL/SQL procedures are already loaded in test database in some other way.
$:.push File.dirname(__FILE__) + '/../source'


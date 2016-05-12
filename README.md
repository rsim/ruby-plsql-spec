[![Build Status](https://travis-ci.org/rsim/ruby-plsql-spec.svg?branch=master)](https://travis-ci.org/rsim/ruby-plsql-spec)

ruby-plsql-spec
===============
PL/SQL unit testing with Ruby
-----------------------------

Unit testing of PL/SQL procedures with Ruby libraries:

* [ruby-plsql](http://github.com/rsim/ruby-plsql) - Ruby API for calling PL/SQL procedures
* [RSpec](http://rspec.info) - Ruby testing (or behavior driven development) framework

Examples
--------

PL/SQL procedure examples are in `examples/source` subdirectory, test examples are in `examples/spec` subdirectory.

* `BETWNSTR` - example from [utPLSQL project](http://utplsql.sourceforge.net/)
* `AWARD_BONUS` - example from [SQL Developer 2.1 tutorial](http://www.oracle.com/technology/obe/11gr2_db_prod/appdev/sqldev/sqldev_unit_test/sqldev_unit_test.htm)
* `REMOVE_ROOMS_BY_NAME` - example from [Quest Code Tester for Oracle tutorial](http://www.quest.com/code-tester-for-oracle/product-demo/chap02.htm)

Installing
----------

See [Installing on Windows](INSTALL-Windows.md) in separate file.

* Install [Ruby 1.8.7, 1.9.3 or 2.x](http://www.ruby-lang.org/en/downloads/) - it is recommended to use latest version
* Install Oracle client, e.g. [Oracle Instant Client](http://www.oracle.com/technology/tech/oci/instantclient/index.html)
* Install ruby-oci8 and ruby-plsql-spec (prefix with sudo if necessary)

        gem install ruby-oci8
        gem install ruby-plsql-spec

Another alternative is to use [JRuby](http://jruby.org) if for example it is necessary also to test Java classes / methods using Ruby.

* Install [JRuby](http://jruby.org/download)
* Copy Oracle JDBC driver (e.g. ojdbc6.jar) to JRUBY_HOME/lib directory
* Install ruby-plsql-spec (prefix with sudo if necessary)

        jruby -S gem install ruby-plsql-spec

Initializing project directory
------------------------------

In your project directory execute

        plsql-spec init

which will create `spec` directory where test files will be located.

Modify `spec/database.yml` file and specify database connection which should be used when running tests. In `database:` parameter specify either TNS connection name or use "servername/databasename" or "servername:port/databasename" to specify host, port and database name.

Start creating tests in files with `_spec.rb` at the end of file name. If there will be not so many files then you can place them directly in `spec` directory. If there will be many tests files then create separate directories per module / functionality group and place tests files in subdirectories. You can also create `factories` and `helpers` subdirectories per each module / functionality group.

Executing tests
---------------

All tests can be run from command line using

        plsql-spec run

or if you want to run tests just from one file then use, e.g.

        plsql-spec run spec/example_spec.rb

You can get additional help about `plsql-spec` command line utility with

        plsql-spec help

Generating HTML RSpec output
----------------------------

If you would like to see a colour HTML report about the test results, just run the tests with --html option:

        plsql-spec run --html [filename]

HTML report will be generated to [filename] file. If you don't specify filename, then it will generated to test-results.html. You can open it in your browser.

Code coverage reporting
-----------------------

If you would like to see PL/SQL code coverage report (which lines of code were executed during tests run) then run tests with --coverage option:

        plsql-spec run --coverage

Coverage reports will be created as HTML files in coverage/ directory. Open with your browser coverage/index.html file.

Code coverage is gathered using DBMS_PROFILER package. Please take into account that only those packages will be analyzed to which current database session user has CREATE privilege.

How to start?
-------------

Read blog post about [Oracle PL/SQL unit testing with Ruby](http://blog.rayapps.com/2009/11/27/oracle-plsql-unit-testing-with-ruby).

If you are not familiar with Ruby I recommend to start with [Ruby in Twenty Minutes](http://www.ruby-lang.org/en/documentation/quickstart/) tutorial. Then you can take a look on some [RSpec examples](http://rspec.info/documentation/) how to write and structure tests. And then you can take a look at [ruby-plsql own tests](http://github.com/rsim/ruby-plsql/blob/master/spec/plsql/procedure_spec.rb) to see how to pass parameters and verify results for different PL/SQL data types.

How to customize ruby-plsql-spec for my project?
------------------------------------------------

* Review spec/spec_helper.rb file and modify if needed directories where you will store additional required files (helper files, factory files, source files).
* Review and or create new helper files in `spec\helpers` directory.
* Create new factory methods for test data creation in `factories` directory (see example in `examples/spec/factories`).

How to upgrade ruby-plsql-spec to latest version
------------------------------------------------

You can see current ruby-plsql-spec version with

        plsql-spec -v

If you want to upgrade ruby-plsql-spec to latest version then just do

        gem install ruby-plsql-spec

If you have upgraded from ruby-plsql-spec version 0.1.0 to 0.2.0 then you need to update your spec_helper.rb file to use rspec 2.0. You can do it by running one more time

        plsql-spec init

which will check which current files are different from the latest templates. You need to update just spec_helper.rb file. When you will be prompted to overwrite spec_helper.rb file then at first you can enter `d` to see differences between current file and new template. If you have not changed original spec_helper.rb file then you will see just one difference

        - Spec::Runner.configure do |config|
        + RSpec.configure do |config|

You can then answer `y` and this file will be updated. When you will be prompted to overwrite other files then you can review the changes in the same way and decide if you want them to be overwritten or not.

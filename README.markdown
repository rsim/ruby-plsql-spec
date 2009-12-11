ruby-plsql-spec
===============
PL/SQL unit testing with Ruby
-----------------------------

Unit testing of PL/SQL procedures with Ruby libraries:

* [ruby-plsql](http://github.com/rsim/ruby-plsql) - Ruby API for calling PL/SQL procedures
* [RSpec](http://rspec.info) - Ruby testing (or behavior driven development) framework

Examples
--------

PL/SQL procedure examples are in `source` subdirectory, test examples are in `spec` subdirectory.

* `BETWNSTR` - example from [utPLSQL project](http://utplsql.sourceforge.net/)
* `AWARD_BONUS` - example from [SQL Developer 2.1 tutorial](http://www.oracle.com/technology/obe/11gr2_db_prod/appdev/sqldev/sqldev_unit_test/sqldev_unit_test.htm)
* `REMOVE_ROOMS_BY_NAME` - example from [Quest Code Tester for Oracle tutorial](http://www.quest.com/code-tester-for-oracle/product-demo/chap02.htm)

Installing
----------

See [Installing on Windows](INSTALL-Windows.markdown) in separate file.

* Install [Ruby 1.8.7 or Ruby 1.9.1](http://www.ruby-lang.org/en/downloads/)
* Install Oracle client, e.g. [Oracle Instant Client](http://www.oracle.com/technology/tech/oci/instantclient/index.html)
* Install rspec, ruby-oci8 and ruby-plsql (prefix with sudo if necessary)

        gem install rspec
        gem install ruby-oci8
        gem install ruby-plsql

Another alternative is to use [JRuby](http://jruby.org) if for example it is necessary also to test Java classes / methods using Ruby.

* Install [JRuby](http://jruby.org/download)
* Copy Oracle JDBC driver (e.g. ojdbc14.jar) to JRUBY_HOME/lib directory
* Install rspec and ruby-plsql (prefix with sudo if necessary)

        jruby -S gem install rspec
        jruby -S gem install ruby-plsql

Executing tests
---------------

All tests can be run from command line using `spec` utility.

* Run all tests in spec directory:

        spec spec

* Run all tests in specified file:

        spec spec/betwnstr_spec.rb

Or you can use text editor or IDE which supports running RSpec tests.

How to start?
-------------

Read blog post about [Oracle PL/SQL unit testing with Ruby](http://blog.rayapps.com/2009/11/27/oracle-plsql-unit-testing-with-ruby).

If you are not familiar with Ruby I recommend to start with [Ruby in Twenty Minutes](http://www.ruby-lang.org/en/documentation/quickstart/) tutorial. Then you can take a look on some [RSpec examples](http://rspec.info/documentation/) how to write and structure tests. And then you can take a look at [ruby-plsql own tests](http://github.com/rsim/ruby-plsql/blob/master/spec/plsql/procedure_spec.rb) to see how to pass parameters and verify results for different PL/SQL data types.

How to add ruby-plsql-spec to a new project?
--------------------------------------------

Create `spec` directory somewhere in your project directory structure where you will keep your ruby-plsql-spec tests. Copy spec_helper.rb to this directory and modify to your needs:

* modify database connection settings
* review other initialization settings (requiring helper files, factory files, source files) and adapt as necessary

Create `helpers` directory. Review and copy needed helper files to helpers directory from this project.

Create `factories` directory where to store definitions of test data factory methods (review example from this project).

Start creating tests in files with `_spec.rb` at the end of file name. If there will be not so many files then you can place them directly in `spec` directory. If there will be many tests files then create separate directories per module / functionality group and place tests files in subdirectories. You can also create `factories` and `helpers` subdirectories per each module / functionality group.

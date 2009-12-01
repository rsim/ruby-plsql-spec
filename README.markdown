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

Other information
-----------------

Read blog post about [Oracle PL/SQL unit testing with Ruby](http://blog.rayapps.com/2009/11/27/oracle-plsql-unit-testing-with-ruby).

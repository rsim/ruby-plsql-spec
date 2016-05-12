Installing on Windows
=====================

Ruby installation on Windows is a little bit different than installation on Mac OS X or Linux therefore here is description of steps for preparing Windows computer for ruby-plsql-spec.

Install Ruby
------------

Download and install Ruby from [Ruby Installer for Windows](http://www.rubyinstaller.org/).

When installing then select checkbox to add Ruby to your PATH.

Verify from command line that you have Ruby installed:

    ruby -v

Install Oracle client
---------------------

You should have Oracle client installed on your computer and its dll directory should be in PATH.

If you do not have Oracle client installed then the easiest way is to install [Oracle Instant Client](http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html) - install Basic and SQL*Plus packages. After installation include Oracle Instant Client directory in PATH.

If needed you can create tnsnames.ora file and enter TNS connections there so that later TNS aliases can be used for connection. Set TNS_ADMIN environment variable to point to directory where tnsnames.ora file is located.

Verify installation and try to connect to database using sqlplus.

Install ruby-oci8
-----------------

[ruby-oci8](http://ruby-oci8.rubyforge.org/en/) Ruby library is providing access to Oracle database from Ruby using OCI interface (provided by Oracle client). Install it with

    gem install ruby-oci8

If you are behind firewall with proxy server then specify proxy server use -p option, e.g.:

    gem install ruby-oci8 -p http://proxy.example.com:8080

Install ruby-plsql-spec
-----------------------

Install ruby-plsql-spec with

    gem install ruby-plsql-spec

Validate installation
---------------------

From command line run `irb` and try to connect to some Oracle database (use appropriate username/password/database instead of "hr","hr","orcl"):

    require "rubygems"
    require "ruby-plsql"
    plsql.connect! "hr","hr","orcl"
    plsql.dual.all

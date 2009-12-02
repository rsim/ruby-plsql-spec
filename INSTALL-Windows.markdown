Installing on Windows
=====================

Ruby installation on Windows is a little bit different than installation on Mac OS X or Linux therefore here is description of steps for preparing Windows computer for ruby-plsql-spec.

Install Ruby
------------

Download and install Ruby 1.8.6 from [Ruby Installer for Windows](http://www.rubyinstaller.org/).
(Ruby 1.9.1 on Windows did not quite work with ruby-oci8 therefore please use version 1.8.6 with ruby-plsql-spec).

Install Oracle client
---------------------

You should have Oracle client installed on your computer and its dll directory should be in PATH.

If you do not have Oracle client installed then the easiest way is to install [Oracle Instant Client](http://www.oracle.com/technology/tech/oci/instantclient/index.html) - install Basic and SQL*Plus packages.
After installation include Oracle Instant Client directory in PATH.
Also it is recommended to create tnsnames.ora file and enter TNS connections there so that later TNS aliases can be used for connection.
Set TNS_ADMIN environment variable to point to directory where tnsnames.ora file is located.
Verify installation and try to connect to database using sqlplus.

Install ruby-oci8
-----------------

[ruby-oci8](http://ruby-oci8.rubyforge.org/en/) Ruby library is providing access to Oracle database from Ruby using OCI interface (provided by Oracle client).

Download latest ruby-oci8 2.0.x Windows gem file from [RubyForge downloads page](http://rubyforge.org/frs/?group_id=256).
At the time of writing it is [ruby-oci8-2.0.3-x86-mswin32-60.gem](http://rubyforge.org/frs/download.php/65895/ruby-oci8-2.0.3-x86-mswin32-60.gem).
Install downloaded file from command line from directory where it is downloaded, e.g.:

    gem install ruby-oci8-2.0.3-x86-mswin32-60.gem

Install remaining gems
----------------------

Install remaining gems with gem command from command line

    gem install rspec
    gem install ruby-plsql

Validate installation
---------------------

From command line run `irb` and try to connect to some Oracle database (use appropriate username/password/database instead of "hr","hr","orcl"):

    require "rubygems"
    require "ruby-plsql"
    plsq.connection = OCI8.new "hr","hr","orcl"
    plsql.dual.all

require 'thor'
require 'thor/actions'
require 'rspec/support'
RSpec::Support.require_rspec_support 'differ'

# use plsql-spec for showing diff of files
# by defuault Thor uses diff utility which is not available on Windows
ENV['THOR_DIFF'] = 'plsql-spec diff'

module PLSQL
  module Spec
    class CLI < ::Thor
      include Thor::Actions

      def initialize(*)
        super
        self.source_paths << File.expand_path('../templates', __FILE__)
      end

      map 'run' => :run_tests, '-v' => :version

      desc 'init', 'initialize spec subdirectory with default ruby-plsql-spec files'
      def init
        empty_directory 'spec/factories'
        copy_file '.rspec', '.rspec'
        directory 'spec', 'spec'
        say <<-EOS, :red

Please update spec/database.yml file and specify your database connection parameters.

Create tests in spec/ directory (or in subdirectories of it) in *_spec.rb files.

Run created tests with "plsql-spec run".
Run tests with "plsql-spec run --coverage" to generate code coverage report in coverage/ directory.
Run tests with "plsql-spec run --html" to generate RSpec report to test-results.html file.
EOS
      end

      desc 'run [FILES]', 'run all *_spec.rb tests in spec subdirectory or specified files'
      method_option :"dbms-output",
          :type => :boolean,
          :default => false,
          :banner => "show DBMS_OUTPUT messages"
      method_option :capture,
          :type => :boolean,
          :default => true,
          :banner => "hide the output when some exception occur"
      method_option :"html",
          :type => :string,
          :banner => "generate HTML RSpec output to specified file (default is test-results.html)"
      method_option :coverage,
          :type => :string,
          :banner => "generate code coverage report in specified directory (defaults to coverage/)"
      method_option :"ignore-schemas",
          :type => :array,
          :banner => "which schemas to ignore when generating code coverage report"
      method_option :like,
          :type => :array,
          :banner => "LIKE condition(s) for filtering which objects to include in code coverage report"
      def run_tests(*files)
        unless File.directory?('spec')
          say "No spec subdirectory in current directory", :red
          exit 1
        end
        ENV['PLSQL_DBMS_OUTPUT'] = 'true' if options[:"dbms-output"]
        ENV['PLSQL_HTML'] = options[:html] if options[:html]
        ENV['PLSQL_COVERAGE'] = options[:coverage] if options[:coverage]
        ENV['PLSQL_COVERAGE_IGNORE_SCHEMAS'] = options[:"ignore-schemas"].join(',') if options[:"ignore-schemas"]
        ENV['PLSQL_COVERAGE_LIKE'] = options[:like].join(',') if options[:like]

        if options[:html]
          # if there is no filename given, the options[:html] == "html"
          spec_output_filename = options[:html] == 'html' ? 'test-results.html' : options[:html]

          speccommand = "rspec --format html --out #{spec_output_filename}"
        else
          speccommand = "rspec"
        end

        if files.empty?
          say "Running all specs from spec/", :yellow
          puts run("#{speccommand} spec", :verbose => false, :capture => options[:capture])
        else
          say "Running specs from #{files.join(', ')}", :yellow
          puts run("#{speccommand} #{files.join(' ')}", :verbose => false, :capture => options[:capture])
        end

        if options[:html]
          say "Test results in #{spec_output_filename}"
        end

        if options[:coverage]
          say "Coverage report in #{options[:coverage]}/index.html"
        end

        unless $?.exitstatus == 0
          say "Failing tests!", :red
          exit 1
        end
      end

      desc 'diff [FILE1] [FILE2]', 'show difference between files'
      def diff(file1, file2)
        differ = RSpec::Support::Differ.new
        say differ.diff_as_string File.read(file2), File.read(file1)
      end

      desc '-v', 'show ruby-plsql-spec and ruby-plsql version'
      def version
        say "ruby-plsql-spec #{PLSQL::Spec::VERSION}"
        say "ruby-plsql      #{PLSQL::VERSION}"
        say "rspec           #{::RSpec::Version::STRING}"
      end

    end

  end
end

require 'thor'
require 'thor/actions'

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
        empty_directory 'spec'
        %w(spec_helper.rb database.yml).each do |file|
          copy_file file, "spec/#{file}"
        end
        directory 'helpers', 'spec/helpers'
        empty_directory 'spec/factories'
        say <<-EOS, :red

Please update spec/database.yml file and specify your database connection parameters.

Create tests in spec/ directory (or in subdirectories of it) in *_spec.rb files.

Run created tests with "plsql-spec run".
Run tests with "plsql-spec run --coverage" to generate code coverage report in coverage/ directory.
EOS
      end

      desc 'run [FILES]', 'run all *_spec.rb tests in spec subdirectory or specified files'
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
        ENV['PLSQL_COVERAGE'] = options[:coverage] if options[:coverage]
        ENV['PLSQL_COVERAGE_IGNORE_SCHEMAS'] = options[:"ignore-schemas"].join(',') if options[:"ignore-schemas"]
        ENV['PLSQL_COVERAGE_LIKE'] = options[:like].join(',') if options[:like]
        if files.empty?
          say "Running all specs from spec/", :yellow
          puts run('spec spec', :verbose => false)
        else
          say "Running specs from #{files.join(', ')}", :yellow
          puts run("spec #{files.join(' ')}", :verbose => false)
        end
        unless $?.exitstatus == 0
          say "Failing tests!", :red
          exit 1
        end
      end

      desc '-v', 'show ruby-plsql-spec and ruby-plsql version'
      def version
        say "ruby-plsql-spec #{PLSQL::Spec::VERSION}"
        say "ruby-plsql      #{PLSQL::VERSION}"
        say "rspec           #{::Spec::VERSION::STRING}"
      end

    end

  end
end
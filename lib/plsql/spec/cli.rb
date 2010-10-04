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
EOS
      end

      desc 'run [FILES]', 'run all *_spec.rb tests in spec subdirectory or specified files'
      def run_tests(*files)
        unless File.directory?('spec')
          say "No spec subdirectory in current directory", :red
          exit 1
        end
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
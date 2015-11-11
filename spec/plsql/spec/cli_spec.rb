require File.expand_path('../../../spec_helper', __FILE__)

describe "plsql-spec" do

  before(:all) do
    @root_dir = destination_root
    FileUtils.rm_rf(@root_dir)
    FileUtils.mkdir_p(@root_dir)
  end

  def run_cli(*args)
    Dir.chdir(@root_dir) do
      @stdout = capture(:stdout) do
        begin
          PLSQL::Spec::CLI.start(args)
        rescue SystemExit => e
          @exit_status = e.status
        end
      end
    end
  end

  def create_database_yml
    content = "default:\n" <<
    "  username: #{DATABASE_USER}\n" <<
    "  password: #{DATABASE_PASSWORD}\n" <<
    "  database: #{DATABASE_SERVICE_NAME}\n"
    content << "  host:     #{DATABASE_HOST}\n" if defined?(DATABASE_HOST)
    content << "  port:     #{DATABASE_PORT}\n" if defined?(DATABASE_PORT)
    File.open(File.join(@root_dir, 'spec/database.yml'), 'w') do |file|
      file.write(content)
    end
  end

  def inject_local_load_path
    spec_helper_file = File.join(@root_dir, 'spec/spec_helper.rb')
    content = File.read(spec_helper_file)
    content.gsub! 'require "ruby-plsql-spec"',
      "$:.unshift(File.expand_path('../../../../lib', __FILE__))\nrequire \"ruby-plsql-spec\""
    File.open(spec_helper_file, 'w') do |file|
      file.write(content)
    end
  end

  def create_test(name, string, options = {})
    file_content = <<-EOS
require_relative './spec_helper'

describe "test" do
  it #{name.inspect} do
    #{string}
  end
end
EOS
    file_name = options[:file_name] || 'test_spec.rb'
    Dir.chdir(@root_dir) do
      File.open("spec/#{file_name}", 'w') do |file|
        file << file_content
      end
    end
  end

  def delete_test_files
    Dir["#{@root_dir}/spec/*_spec.rb"].each do |file_name|
      FileUtils.rm_f(file_name)
    end
  end

  describe "init" do
    before(:all) do
      run_cli('init')
    end

    it "should create spec subdirectory" do
      expect(File.directory?(@root_dir + '/spec')).to be_truthy
    end

    it "should create spec_helper.rb" do
      expect(File.file?(@root_dir + '/spec/spec_helper.rb')).to be_truthy
    end

    it "should create database.yml" do
      expect(File.file?(@root_dir + '/spec/database.yml')).to be_truthy
    end

    it "should create helpers/inspect_helpers.rb" do
      expect(File.file?(@root_dir + '/spec/helpers/inspect_helpers.rb')).to be_truthy
    end

    it "should create factories subdirectory" do
      expect(File.directory?(@root_dir + '/spec/factories')).to be_truthy
    end

    it "should create .rspec" do
      expect(File.file?(@root_dir + '/.rspec')).to be_truthy
    end

  end

  describe "run" do
    before(:all) do
      run_cli('init')
      create_database_yml
      inject_local_load_path
    end

    describe "successful tests" do
      before(:all) do
        create_test 'SYSDATE should not be NULL',
          'expect(plsql.sysdate).not_to eq(NULL)'
        run_cli('run')
      end

      it "should report zero failures" do
        expect(@stdout).to match(/ 0 failures/)
      end

      it "should not return failing exit status" do
        expect(@exit_status).to be_nil
      end
    end

    describe "failing tests" do
      before(:all) do
        create_test 'SYSDATE should be NULL',
          'expect(plsql.sysdate).to eq(NULL)'
        run_cli('run')
      end

      it "should report failures" do
        expect(@stdout).to match(/ 1 failure/)
      end

      it "should return failing exit status" do
        expect(@exit_status).to eq(1)
      end
    end

    describe "specified files" do
      before(:all) do
        create_test 'SYSDATE should not be NULL',
          'expect(plsql.sysdate).not_to eq(NULL)'
        create_test 'SYSDATE should be NULL',
          'expect(plsql.sysdate).to eq(NULL)',
          :file_name => 'test2_spec.rb'
      end

      after(:all) do
        delete_test_files
      end

      it "should report one file examples" do
        run_cli('run', 'spec/test_spec.rb')
        expect(@stdout).to match(/1 example/)
      end

      it "should report two files examples" do
        run_cli('run', 'spec/test_spec.rb', 'spec/test2_spec.rb')
        expect(@stdout).to match(/2 examples/)
      end
    end

    describe "with coverage" do
      before(:all) do
        plsql.connect! CONNECTION_PARAMS
        plsql.execute <<-SQL
          CREATE OR REPLACE FUNCTION test_profiler RETURN VARCHAR2 IS
          BEGIN
            RETURN 'test_profiler';
          EXCEPTION
            WHEN OTHERS THEN
              RETURN 'others';
          END;
        SQL
        create_test 'shoud test coverage',
          'expect(plsql.test_profiler).to eq("test_profiler")'
        @index_file = File.join(@root_dir, 'coverage/index.html')
        @details_file = File.join(@root_dir, "coverage/#{DATABASE_USER.upcase}-TEST_PROFILER.html")
      end

      after(:all) do
        plsql.execute "DROP FUNCTION test_profiler" rescue nil
      end

      before(:each) do
        FileUtils.rm_rf File.join(@root_dir, 'coverage')
      end

      after(:each) do
        %w(PLSQL_COVERAGE PLSQL_COVERAGE_IGNORE_SCHEMAS PLSQL_COVERAGE_LIKE).each do |variable|
          ENV.delete variable
        end
      end

      it "should report zero failures" do
        run_cli('run', '--coverage')
        expect(@stdout).to match(/ 0 failures/)
      end

      it "should generate coverage reports" do
        run_cli('run', '--coverage')
        expect(File.file?(@index_file)).to be_truthy
        expect(File.file?(@details_file)).to be_truthy
      end

      it "should generate coverage reports in specified directory" do
        run_cli('run', '--coverage', 'plsql_coverage')
        expect(File.file?(@index_file.gsub('coverage', 'plsql_coverage'))).to be_truthy
        expect(File.file?(@details_file.gsub('coverage', 'plsql_coverage'))).to be_truthy
      end

      it "should not generate coverage report for ignored schema" do
        run_cli('run', '--coverage', '--ignore_schemas', DATABASE_USER)
        expect(File.file?(@details_file)).to be_falsey
      end

      it "should generate coverage report for objects matching like condition" do
        run_cli('run', '--coverage', '--like', "#{DATABASE_USER}.%")
        expect(File.file?(@details_file)).to be_truthy
      end

      it "should not generate coverage report for objects not matching like condition" do
        run_cli('run', '--coverage', '--like', "#{DATABASE_USER}.aaa%")
        expect(File.file?(@details_file)).to be_falsey
      end

    end

    describe "with dbms_output" do
      before(:all) do
        plsql.connect! CONNECTION_PARAMS
        plsql.execute <<-SQL
          CREATE OR REPLACE PROCEDURE test_dbms_output IS
          BEGIN
            DBMS_OUTPUT.PUT_LINE('test_dbms_output');
          END;
        SQL
        create_test 'shoud test dbms_output',
          'expect(plsql.test_dbms_output).to be_nil'
      end

      after(:all) do
        plsql.execute "DROP PROCEDURE test_dbms_output" rescue nil
      end

      after(:each) do
        ENV.delete 'PLSQL_DBMS_OUTPUT'
      end

      it "should show DBMS_OUTPUT in standard output" do
        run_cli('run', '--dbms_output')
        expect(@stdout).to match(/DBMS_OUTPUT: test_dbms_output/)
      end

      it "should not show DBMS_OUTPUT without specifying option" do
        run_cli('run')
        expect(@stdout).not_to match(/DBMS_OUTPUT: test_dbms_output/)
      end

    end

    describe "with html output" do
      before(:all) do
        create_test 'SYSDATE should not be NULL',
          'expect(plsql.sysdate).not_to eq(NULL)'
        @default_html_file = File.join(@root_dir, 'test-results.html')
        @custom_file_name = 'custom-results.html'
        @custom_html_file = File.join(@root_dir, @custom_file_name)
      end

      def delete_html_output_files
        FileUtils.rm_rf @default_html_file
        FileUtils.rm_rf @custom_html_file
      end

      before(:each) do
        delete_html_output_files
      end

      after(:all) do
        delete_html_output_files
      end

      it "should create default report file" do
        run_cli('run', '--html')
        expect(File.read(@default_html_file)).to match(/ 0 failures/)
      end

      it "should create specified report file" do
        run_cli('run', '--html', @custom_file_name)
        expect(File.read(@custom_html_file)).to match(/ 0 failures/)
      end

    end

  end

  describe "version" do
    before(:all) do
      run_cli('-v')
    end

    it "should show ruby-plsql-spec version" do
      expect(@stdout).to match(/ruby-plsql-spec\s+#{PLSQL::Spec::VERSION.gsub('.','\.')}/)
    end

    it "should show ruby-plsql version" do
      expect(@stdout).to match(/ruby-plsql\s+#{PLSQL::VERSION.gsub('.','\.')}/)
    end

    it "should show rspec version" do
      expect(@stdout).to match(/rspec\s+#{::RSpec::Version::STRING.gsub('.','\.')}/)
    end

  end

  describe "diff" do
    before(:all) do
      @test_strings = %w(test1 test2)
      @test_files = %w(test1.txt test2.txt)
      @test_strings.each_with_index do |string, i|
        File.open(File.join(@root_dir, @test_files[i]), 'w') do |file|
          file.write(string)
        end
      end
      run_cli('diff', *@test_files.map{|file| File.join(@root_dir, file)})
    end

    after(:all) do
      @test_files.each do |file|
        FileUtils.rm_f(File.join(@root_dir, file))
      end
    end

    it "should show diff" do
      expect(@stdout).to match(/^\-#{@test_strings[0]}$/)
      expect(@stdout).to match(/^\+#{@test_strings[1]}$/)
    end
  end

end

require 'spec_helper'

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
    "  database: #{DATABASE_NAME}\n"
    content << "  host:     #{DATABASE_HOST}\n" if DATABASE_HOST
    content << "  port:     #{DATABASE_PORT}\n" if DATABASE_PORT
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

  def create_test(name, string)
    file_content = <<-EOS
require 'spec_helper'

describe "test" do
  it #{name.inspect} do
    #{string}
  end
end
EOS
    Dir.chdir(@root_dir) do
      File.open('spec/test_spec.rb', 'w') do |file|
        file << file_content
      end
    end
  end

  describe "init" do
    before(:all) do
      run_cli('init')
    end

    it "should create spec subdirectory" do
      File.directory?(@root_dir + '/spec').should be_true
    end

    it "should create spec_helper.rb" do
      File.file?(@root_dir + '/spec/spec_helper.rb').should be_true
    end

    it "should create database.yml" do
      File.file?(@root_dir + '/spec/database.yml').should be_true
    end

    it "should create helpers/inspect_helpers.rb" do
      File.file?(@root_dir + '/spec/helpers/inspect_helpers.rb').should be_true
    end

    it "should create factories subdirectory" do
      File.directory?(@root_dir + '/spec/factories').should be_true
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
        create_test 'SYSDATE should not be NULL ',
          'plsql.sysdate.should_not == NULL'
        run_cli('run')
      end

      it "should report zero failures" do
        @stdout.should =~ / 0 failures/
      end

      it "should not return failing exit status" do
        @exit_status.should be_nil
      end
    end

    describe "failing tests" do
      before(:all) do
        create_test 'SYSDATE should be NULL ',
          'plsql.sysdate.should == NULL'
        run_cli('run')
      end

      it "should report failures" do
        @stdout.should =~ / 1 failure/
      end

      it "should return failing exit status" do
        @exit_status.should == 1
      end
    end

    describe "specified files" do
      before(:all) do
        create_test 'SYSDATE should not be NULL ',
          'plsql.sysdate.should_not == NULL'
      end

      it "should report one file examples" do
        run_cli('run', 'spec/test_spec.rb')
        @stdout.should =~ /1 example/
      end

      it "should report two files examples" do
        run_cli('run', 'spec/test_spec.rb', 'spec/test_spec.rb')
        @stdout.should =~ /2 examples/
      end
    end
  end

  describe "version" do
    before(:all) do
      run_cli('-v')
    end

    it "should show ruby-plsql-spec version" do
      @stdout.should =~ /ruby-plsql-spec\s+#{PLSQL::Spec::VERSION.gsub('.','\.')}/
    end

    it "should show ruby-plsql version" do
      @stdout.should =~ /ruby-plsql\s+#{PLSQL::VERSION.gsub('.','\.')}/
    end

    it "should show rspec version" do
      @stdout.should =~ /rspec\s+#{::Spec::VERSION::STRING.gsub('.','\.')}/
    end

  end
end

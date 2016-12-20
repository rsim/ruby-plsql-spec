require File.expand_path('../../spec_helper', __FILE__)

describe "Coverage" do
  def drop_profiler_tables
    %w(plsql_profiler_data plsql_profiler_units plsql_profiler_runs).each do |table_name|
      plsql.execute "drop table #{table_name} cascade constraints" rescue nil
    end
  end

  before(:all) do
    PLSQL::Coverage.reset_cache

    plsql.connect! CONNECTION_PARAMS
    plsql.execute "ALTER SESSION SET PLSQL_OPTIMIZE_LEVEL=1"
    drop_profiler_tables
    @source = <<-SQL
CREATE OR REPLACE FUNCTION test_profiler RETURN VARCHAR2 IS

-- A comment before executed code
BEGIN
  RETURN 'test_profiler';
  -- A dummy empty line follows

EXCEPTION
  WHEN OTHERS THEN
    -- We should never reach here
    RETURN 'others';
END;
    SQL
    plsql.execute @source

    @coverage_data = {
      DATABASE_USER.upcase => {
        "TEST_PROFILER" => {
          "FUNCTION" => {
            1=>1,
            4=>1,
            5=>1,
            8=>0,
            9=>0,
            11=>0,
            12=>1
          }
        }
      }
    }

    FileUtils.rm_rf(destination_root)
    @directory = File.join(destination_root, 'coverage')
  end

  after(:all) do
    plsql.execute "DROP FUNCTION test_profiler" rescue nil
    drop_profiler_tables
  end

  describe "start" do
    before(:all) do
      @start_result = PLSQL::Coverage.start
    end

    it "should start coverage collection" do
      expect(@start_result).to be_truthy
    end

    it "should create profiler tables" do
      %w(plsql_profiler_data plsql_profiler_units plsql_profiler_runs).each do |table_name|
        expect(plsql.send(table_name)).to be_a(PLSQL::Table)
      end
    end

    it "should start collecting profiler data" do
      expect(plsql.plsql_profiler_runs.all).not_to be_empty
    end

  end

  describe "stop" do
    before(:all) do
      PLSQL::Coverage.start
      plsql.test_profiler
      @stop_result = PLSQL::Coverage.stop
    end

    it "should stop coverage collection" do
      expect(@stop_result).to be_truthy
    end

    it "should populate profiler data table" do
      expect(plsql.plsql_profiler_data.all).not_to be_empty
    end

  end

  describe "cleanup" do
    before(:each) do
      PLSQL::Coverage.start
      plsql.test_profiler
      PLSQL::Coverage.stop
    end

    it "should drop profiler tables" do
      expect(PLSQL::Coverage.cleanup).to be_truthy
      %w(plsql_profiler_data plsql_profiler_units plsql_profiler_runs).each do |table_name|
        expect(PLSQL::Table.find(plsql, table_name.to_sym)).to be_nil
      end
    end

    it "should delete profiler table data when profiler tables already were present" do
      # simulate that profiler tables were already present
      PLSQL::Coverage.reset_cache
      expect {
        PLSQL::Coverage.start
        plsql.test_profiler
        PLSQL::Coverage.stop
        PLSQL::Coverage.cleanup
      }.not_to change {
        [plsql.plsql_profiler_data.all, plsql.plsql_profiler_units.all, plsql.plsql_profiler_runs.all]
      }
    end
  end

  describe "get coverage data" do

    context "when a PLSQL function is run" do
      before(:all) do
        PLSQL::Coverage.start
        plsql.test_profiler
        PLSQL::Coverage.stop
      end

      it "should get profiler run results" do
        expect(PLSQL::Coverage.find.coverage_data).to eq(@coverage_data)
      end

      it "should not get ignored schemas" do
        expect(PLSQL::Coverage.find.coverage_data(:ignore_schemas => [DATABASE_USER])).to be_empty
      end

      it "should get only objects with like condition" do
        expect(PLSQL::Coverage.find.coverage_data(:like => "#{DATABASE_USER}.test%")).to eq(@coverage_data)
      end

      it "should not get objects not matching like condition" do
        expect(PLSQL::Coverage.find.coverage_data(:like => "#{DATABASE_USER}.none%")).to be_empty
      end
    end

    context "when a PLSQL PACKAGE is run" do
      before(:all) do
        @package = <<-SQL
          CREATE OR REPLACE PACKAGE mailman_package AS
            VAR_TEST CONSTANT NUMBER := 12345;
            PROCEDURE TEST_PROC;
          END;
        SQL

        @package_body = <<-SQL
          CREATE OR REPLACE PACKAGE BODY mailman_package AS
            PROCEDURE TEST_PROC AS
            BEGIN
              EXECUTE IMMEDIATE 'SELECT 1 AS TEST FROM DUAL';
            END;
          END;
        SQL

        plsql.execute @package
        plsql.execute @package_body

        @package_coverage = {
          DATABASE_USER.upcase => {
            "MAILMAN_PACKAGE" => {
              "PACKAGE SPEC" => {
                1=>1,
                2=>1,
                4=>1
              },
              "PACKAGE BODY" => {
                2=>1,
                3=>1,
                4=>1,
                5=>1
              }
            }
          }
        }

        PLSQL::Coverage.start
        plsql.mailman_package.var_test
        plsql.mailman_package.test_proc
        PLSQL::Coverage.stop
      end

      after(:all) do
        plsql.execute "DROP PACKAGE mailman_package" rescue nil
      end

      it "should get mailman_package run results" do
        expect(PLSQL::Coverage.find.coverage_data).to eq(@package_coverage)
      end
    end

  end

  describe "generate" do
    def adjust_test_coverage
      @test_coverage = @coverage_data[DATABASE_USER.upcase]['TEST_PROFILER']['FUNCTION'].dup
      @test_coverage.delete(1) if @test_coverage[1] == 0 && @source.split("\n")[0] =~ /^CREATE OR REPLACE (.*)$/
    end

    def expected_coverages
      total_lines = @source.split("\n").size
      uncovered_lines = @test_coverage.count{|k,v| v==0}
      executed_lines = @test_coverage.count{|k,v| v>0}
      total_coverage_pct = '%.2f' % ((total_lines - uncovered_lines).to_f / total_lines * 100) + '%'
      code_coverage_pct = '%.2f' % (executed_lines.to_f / (executed_lines + uncovered_lines) * 100) + '%'
      [total_coverage_pct, code_coverage_pct]
    end

    before(:all) do
      PLSQL::Coverage.start
      plsql.test_profiler
      PLSQL::Coverage.stop
      PLSQL::Coverage.report(:directory => @directory)

      adjust_test_coverage
    end

    after(:all) do
      PLSQL::Coverage.cleanup
    end

    describe "details report" do
      before(:all) do
        @details_doc = Nokogiri::HTML(File.read(File.join(@directory, "#{DATABASE_USER.upcase}-TEST_PROFILER.html")))
      end

      it "should generate HTML table with source lines" do
        @source.split("\n").each_with_index do |line, i|
          if i == 0 && line =~ /^CREATE OR REPLACE (.*)$/
            line = $1
          end
          line.chomp!

          # line should be present
          a = @details_doc.at_css("table.details a[name=\"line#{i+1}\"]")
          expect(a).not_to be_nil

          doc_line = a.parent.children[1]
          doc_line_text = doc_line ? doc_line.text : ""

          # source text should be present
          expect(doc_line_text).to eq(line)

          # table row should have correct class according to coverage data
          tr = a.ancestors('tr')[0]
          expect(tr.attr('class')).to eq(case @test_coverage[i+1]
            when nil
              'inferred'
            when 0
              'uncovered'
            else
              'marked'
            end)
        end
      end

      it "should generate HTML table with coverage percentage" do
        expect(@details_doc.css("table.report div.percent_graph_legend").map{|div| div.text}).to eq(expected_coverages)
      end

    end

    describe "index report" do
      before(:all) do
        @index_doc = Nokogiri::HTML(File.read(File.join(@directory, "index.html")))
      end

      it "should generate HTML table with coverage percentage" do
        expect(@index_doc.css("table.report tbody tr:contains('HR.TEST_PROFILER') div.percent_graph_legend").map{|div| div.text}).to eq(expected_coverages)
        expect(@index_doc.css("table.report tfoot div.percent_graph_legend").map{|div| div.text}).to eq(expected_coverages)
      end

    end

  end

  describe "using other connection" do
    before(:all) do
      plsql.logoff
      plsql(:other).connect! CONNECTION_PARAMS

      PLSQL::Coverage.start(:other)
      plsql(:other).test_profiler
      PLSQL::Coverage.stop(:other)
    end

    after(:all) do
      plsql(:other).execute "DROP FUNCTION test_profiler" rescue nil
      PLSQL::Coverage.cleanup(:other)
    end

    it "should start collecting profiler data" do
      expect(plsql(:other).plsql_profiler_runs.all).not_to be_empty
    end

    it "should populate profiler data table" do
      expect(plsql(:other).plsql_profiler_data.all).not_to be_empty
    end

    it "should get profiler run results" do
      expect(PLSQL::Coverage.find(:other).coverage_data).to eq(@coverage_data)
    end

    it "should generate reports" do
      PLSQL::Coverage.report :other, :directory => File.join(@directory, 'other')
      expect(File.file?(File.join(@directory, 'other/index.html'))).to be_truthy
    end
  end

end

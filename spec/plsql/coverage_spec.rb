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
    drop_profiler_tables
    @source = <<-SQL
CREATE OR REPLACE FUNCTION test_profiler RETURN VARCHAR2 IS
BEGIN
  RETURN 'test_profiler';
EXCEPTION
  WHEN OTHERS THEN
    RETURN 'others';
END;
    SQL
    plsql.execute @source

    @coverage_data = {
      DATABASE_USER.upcase => {
        "TEST_PROFILER" => {
          1=>0,
          3=>1,
          6=>0,
          7=>1
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
      @start_result.should be_true
    end

    it "should create profiler tables" do
      %w(plsql_profiler_data plsql_profiler_units plsql_profiler_runs).each do |table_name|
        plsql.send(table_name).should be_a(PLSQL::Table)
      end
    end

    it "should start collecting profiler data" do
      plsql.plsql_profiler_runs.all.should_not be_empty
    end

  end

  describe "stop" do
    before(:all) do
      PLSQL::Coverage.start
      plsql.test_profiler
      @stop_result = PLSQL::Coverage.stop
    end

    it "should stop coverage collection" do
      @stop_result.should be_true
    end

    it "should populate profiler data table" do
      plsql.plsql_profiler_data.all.should_not be_empty
    end

  end

  describe "cleanup" do
    before(:each) do
      PLSQL::Coverage.start
      plsql.test_profiler
      PLSQL::Coverage.stop
    end

    it "should drop profiler tables" do
      PLSQL::Coverage.cleanup.should be_true
      %w(plsql_profiler_data plsql_profiler_units plsql_profiler_runs).each do |table_name|
        PLSQL::Table.find(plsql, table_name.to_sym).should be_nil
      end
    end

    it "should delete profiler table data when profiler tables already were present" do
      # simulate that profiler tables were already present
      PLSQL::Coverage.reset_cache
      lambda {
        PLSQL::Coverage.start
        plsql.test_profiler
        PLSQL::Coverage.stop
        PLSQL::Coverage.cleanup
      }.should_not change {
        [plsql.plsql_profiler_data.all, plsql.plsql_profiler_units.all, plsql.plsql_profiler_runs.all]
      }
    end
  end

  describe "get coverage data" do
    before(:all) do
      PLSQL::Coverage.start
      plsql.test_profiler
      PLSQL::Coverage.stop
    end

    it "should get profiler run results" do
      PLSQL::Coverage.find.coverage_data.should == @coverage_data
    end

    it "should not get ignored schemas" do
      PLSQL::Coverage.find.coverage_data(:ignore_schemas => [DATABASE_USER]).should be_empty
    end

    it "should get only objects with like condition" do
      PLSQL::Coverage.find.coverage_data(:like => "#{DATABASE_USER}.test%").should == @coverage_data
    end

    it "should not get objects not matching like condition" do
      PLSQL::Coverage.find.coverage_data(:like => "#{DATABASE_USER}.none%").should be_empty
    end

  end

  describe "generate" do
    def adjust_test_coverage
      @test_coverage = @coverage_data[DATABASE_USER.upcase]['TEST_PROFILER'].dup
      @test_coverage.delete(1) if @test_coverage[1] && @source.split("\n")[0] =~ /^CREATE OR REPLACE (.*)$/
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
          a.should_not be_nil

          # source text should be present
          a.parent.children[1].text.should == line

          # table row should have correct class according to coverage data
          tr = a.ancestors('tr')[0]
          tr.attr('class').should == case @test_coverage[i+1]
            when nil
              'inferred'
            when 0
              'uncovered'
            else
              'marked'
            end
        end
      end

      it "should generate HTML table with coverage percentage" do
        @details_doc.css("table.report div.percent_graph_legend").map{|div| div.text}.should == expected_coverages
      end

    end

    describe "index repot" do
      before(:all) do
        @index_doc = Nokogiri::HTML(File.read(File.join(@directory, "index.html")))
      end

      it "should generate HTML table with coverage percentage" do
        @index_doc.css("table.report tbody div.percent_graph_legend").map{|div| div.text}.should == expected_coverages
        @index_doc.css("table.report tfoot div.percent_graph_legend").map{|div| div.text}.should == expected_coverages
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
      plsql(:other).plsql_profiler_runs.all.should_not be_empty
    end

    it "should populate profiler data table" do
      plsql(:other).plsql_profiler_data.all.should_not be_empty
    end

    it "should get profiler run results" do
      PLSQL::Coverage.find(:other).coverage_data.should == @coverage_data
    end

    it "should generate reports" do
      PLSQL::Coverage.report :other, :directory => File.join(@directory, 'other')
      File.file?(File.join(@directory, 'other/index.html')).should be_true
    end
  end

end
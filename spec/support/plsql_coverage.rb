require 'erb'
require 'fileutils'

module PLSQL
  class Coverage
    def self.start
      # ignore repeated invocation
      return if @started
      create_profiler_tables
      result = plsql.dbms_profiler.start_profiler(
        :run_comment => "ruby-plsql-spec #{Time.now.xmlschema}",
        :run_number => nil
      )
      @run_number = result[1][:run_number]
      @coverages = nil
      @started = true
    end

    def self.stop
      # ignore repeated invocation
      return unless @started
      plsql.dbms_profiler.stop_profiler
      @started = false
    end

    def self.create_profiler_tables
      unless PLSQL::Table.find(plsql, 'plsql_profiler_data')
        proftab_file = File.expand_path('../proftab.sql', __FILE__)
        File.read(proftab_file).split(";\n").each do |sql|
          if sql =~ /^drop/i
            plsql.execute sql rescue nil
          elsif sql =~ /^(create|comment)/i
            plsql.execute sql
          end
        end
        @created_profiler_tables = true
      end
    end

    def self.drop_or_delete_profiler_tables
      if @created_profiler_tables
        %w(plsql_profiler_data plsql_profiler_units plsql_profiler_runs).each do |table|
          plsql.execute "DROP TABLE #{table} CASCADE CONSTRAINTS"
        end
        plsql.execute "DROP SEQUENCE plsql_profiler_runnumber"
      else @run_number
        plsql.execute <<-SQL, @run_number
          DECLARE
            PRAGMA AUTONOMOUS_TRANSACTION;
            v_runid BINARY_INTEGER := :runid;
          BEGIN
            DELETE FROM plsql_profiler_data WHERE runid = v_runid;
            DELETE FROM plsql_profiler_units WHERE runid = v_runid;
            DELETE FROM plsql_profiler_runs WHERE runid = v_runid;
            COMMIT;
          END;
        SQL
      end
    end

    def self.get_coverage(options)
      quoted_ignore_schemas = if options[:ignore_schemas]
        options[:ignore_schemas].map{|schema| quote_condition_string(schema)}
      else
        %w('SYS')
      end
      quoted_ignore_schemas << "'<anonymous>'"
      like_condition = if options[:like]
        'AND ((' << Array(options[:like]).map do |like|
          like_schema, like_object = like.split('.')
          condition = "u.unit_owner LIKE #{quote_condition_string(like_schema)}"
          condition << " AND u.unit_name LIKE #{quote_condition_string(like_object)}" if like_object
        end.join(') OR (') << '))'
      else
        nil
      end
      @coverages = {}
      rows = plsql.select_all <<-EOS
        SELECT u.unit_owner, u.unit_name, d.line# line_number, d.total_occur
        FROM plsql_profiler_units u, plsql_profiler_data d
        WHERE u.runid = #{@run_number}
          AND u.unit_owner NOT IN (#{quoted_ignore_schemas.join(',')})
          AND u.runid = d.runid
          AND u.unit_number = d.unit_number
          #{like_condition}
        ORDER BY u.unit_owner, u.unit_name, d.line#
      EOS
      rows.each do |row|
        unit_owner, unit_name, line_number, total_occur = row
        @coverages[unit_owner] ||= {}
        @coverages[unit_owner][unit_name] ||= {}
        @coverages[unit_owner][unit_name][line_number] = total_occur
      end

      drop_or_delete_profiler_tables
    end

    def self.report(options)
      # prevent repeated invocation after coverage is reported
      return if @coverages
      @directory = options.delete(:directory)
      get_coverage(options)
      create_static_files

      # Read templates
      @details_template = ERB.new DETAILS_TEMPLATE, nil, '><'
      @table_line_template = ERB.new TABLE_LINE_TEMPLATE, nil, '><'
      @index_template = ERB.new INDEX_TEMPLATE, nil, '><'

      @table_lines = []
      @total_lines = @analyzed_lines = @executed_lines = 0

      # Loop through each database object, evaluating it along with the template
      @coverages.keys.sort.each do |schema|
        @coverages[schema].keys.sort.each do |object|
          details_report(schema, object, @coverages[schema][object])
        end
      end

      index_report
    end

    def self.details_report(schema, object, lines)
      source = plsql.select_all <<-EOS, schema, object
        SELECT s.line, s.text
        FROM all_source s
        WHERE s.owner = :owner
          AND s.name = :name
          AND s.type NOT IN ('PACKAGE')
        ORDER BY s.line
      EOS
      coverage = (@coverages[schema]||{})[object]||{}

      total_lines = source.length
      # return if no access to source of database object
      # or if package body is wrapped
      return if total_lines == 0 || source[0][1] =~ /^\s*PACKAGE BODY .* WRAPPED/i

      # sometimes first PROCEDURE or FUNCTION line is reported as not executed, force ignoring it
      source.each do |line, text|
        if text =~ /^\s*(PROCEDURE|FUNCTION)/ && coverage[line] == 0
          coverage.delete(line)
        end
      end

      @total_lines += total_lines
      analyzed_lines = executed_lines = 0
      coverage.each do |line, value|
        analyzed_lines += 1
        executed_lines += 1 if value > 0
      end
      @analyzed_lines += analyzed_lines
      @executed_lines += executed_lines
      total_coverage = (total_lines - analyzed_lines + executed_lines).to_f / total_lines * 100
      code_coverage = analyzed_lines > 0 ? executed_lines.to_f / analyzed_lines * 100 : 0

      file_name = "#{schema}-#{object}.html"
      object_name = "#{schema}.#{object}"

      table_line_html = @table_line_template.result binding
      @table_lines << table_line_html
      html = @details_template.result binding

      File.open("#{@directory}/#{file_name}", "w") do |file|
        file.write html
      end
    end

    def self.index_report
      schemas = @coverages.keys.sort
      table_lines_html = @table_lines.join("\n")

      total_lines, analyzed_lines, executed_lines = @total_lines, @analyzed_lines, @executed_lines
      # return if no access to source of database objects
      return if total_lines == 0

      total_coverage = (total_lines - analyzed_lines + executed_lines).to_f / total_lines * 100
      code_coverage = analyzed_lines > 0 ? executed_lines.to_f / analyzed_lines * 100 : 0

      schema = file_name = nil
      object_name = 'TOTAL'

      table_footer_html = @table_line_template.result binding

      html = @index_template.result binding

      File.open("#{@directory}/index.html", "w") do |file|
        file.write html
      end
    end

    private

    def self.create_static_files
      FileUtils.mkdir_p("#{@directory}")
      %w(coverage.css jquery.min.js jquery.tablesorter.min.js rcov.js).each do |file|
        FileUtils.cp File.expand_path("../#{file}", __FILE__), "#{@directory}/#{file}"
      end
    end

    def self.quote_condition_string(string)
      "'#{string.to_s.upcase.gsub(/[^\w\d\$\%\_]/,'')}'"
    end


    DETAILS_TEMPLATE = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
  <title><%= object_name %> - coverage report</title>
  <link href="coverage.css" media="all" rel="stylesheet" type="text/css">
</head>
<body>
  <h1><%= object_name %></h1>
  <div class="report_table_wrapper">
    <table class='report' id='report_table'>
      <%= TABLE_HEADER_TEMPLATE %>
      <tbody>
        <%= table_line_html %>
      </tbody>
    </table>
  </div> 
  <table class="details">
    <% source.each do |line, text| %>
      <% classname = (cov = coverage[line]) ? (cov > 0 ? 'marked' : 'uncovered') : 'inferred' %>
      <tr class="<%= classname %>" <%= (cov = coverage[line]) ? 'data-hits="'+cov.to_s+'"' : '' %>>
        <td><pre><a name="line<%= line %>"><%= line %> </a><%= ERB::Util.h text.chomp %></pre></td>
      </tr>
    <% end %>
  </table>
</body>
</html>
HTML

    TABLE_HEADER_TEMPLATE = <<-HTML
      <thead>
        <tr>
          <th class="left_align">Name</th>
          <th class="right_align">Total Lines</th>
          <th class="right_align">Analyzed Lines</th>
          <th class="left_align">Total Coverage</th>
          <th class="left_align">Code Coverage</th>
        </tr>
      </thead>
HTML

    TABLE_LINE_TEMPLATE = <<-HTML
        <tr class="all_schemas all_coverage <%= schema %>_schema <%= ((code_coverage.to_i/10)..(code_coverage==100 ? 10 : 9)).map{|i| (i+1).to_s<<'0'}.join(' ') %>">
          <td class="left_align"><a href="<%= file_name %>"><%= object_name %></a></td>
          <td class='right_align'><tt><%= total_lines %></tt></td>
          <td class='right_align'><tt><%= analyzed_lines %></tt></td>
          <td class="left_align"><div class="percent_graph_legend"><tt class=''><%= '%.2f' % total_coverage %>%</tt></div>
        <div class="percent_graph">
          <div class="covered" style="width:<%= total_coverage.to_i %>px"></div>
          <div class="uncovered" style="width:<%= 100 - total_coverage.to_i %>px"></div>
        </div></td>
          <td class="left_align"><div class="percent_graph_legend"><tt class=''><%= '%.2f' % code_coverage %>%</tt></div>
        <div class="percent_graph">
          <div class="covered" style="width:<%= code_coverage.to_i %>px"></div>
          <div class="uncovered" style="width:<%= 100 - code_coverage.to_i %>px"></div>
        </div></td>
        </tr>
HTML

    INDEX_TEMPLATE = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
  <title>ruby-plsql-spec coverage report</title>
  <link href="coverage.css" media="all" rel="stylesheet" type="text/css" />

  <script type="text/javascript" src="jquery.min.js"></script>
  <script type="text/javascript" src="jquery.tablesorter.min.js"></script>
  <script type="text/javascript" src="rcov.js"></script> 
</head>
<body>
  <h1>ruby-plsql-spec coverage report</h1> 


  <noscript><style type="text/css">.if_js { display:none; }</style></noscript>

  <div class="filters if_js">
    <fieldset>
      <label>Object Filter:</label>
      <select id="file_filter" class="filter">
        <option value="all_schemas">Show all</option>
        <% schemas.each do |schema| %>
          <option value="<%= schema %>_schema"><%= schema %>.%</option>
        <% end %>
      </select>
    </fieldset>
    <fieldset>
      <label>Code Coverage Threshold:</label> 
      <select id="coverage_filter" class="filter"> 
        <option value="all_coverage">Show All</option> 
        <option value="10">&lt; 10% Coverage</option>
        <option value="20">&lt; 20% Coverage</option>
        <option value="30">&lt; 30% Coverage</option>
        <option value="40">&lt; 40% Coverage</option>
        <option value="50">&lt; 50% Coverage</option>
        <option value="60">&lt; 60% Coverage</option>
        <option value="70">&lt; 70% Coverage</option>
        <option value="80">&lt; 80% Coverage</option>
        <option value="90">&lt; 90% Coverage</option>
        <option value="100">&lt; 100% Coverage</option>
        <option value="110">= 100% Coverage</option>
      </select>
    </fieldset>
  </div>

  <div class="report_table_wrapper">
    <table class='report' id='report_table'>
      <%= TABLE_HEADER_TEMPLATE %>
      <tfoot>
        <%= table_footer_html %>
      </tfoot>
      <tbody>
        <%= table_lines_html %>
      </tbody>
    </table>
  </div>

  <p>Generated at <%= Time.now.xmlschema.gsub('T', ' ') %> with <a href="http://github.com/rsim/ruby-plsql-spec">ruby-plsql-spec</a>
    using <a href="http://github.com/relevance/rcov">rcov</a> template.</p>

</body>
</html>
HTML

  end
end

module PLSQL
  class Coverage
    @@coverages = {}

    attr_accessor :directory

    # used in tests to reset coverages cache
    def self.reset_cache
      @@coverages = {}
    end

    def self.start(connection_alias = nil)
      find_or_new(connection_alias).start
    end

    def initialize(connection_alias)
      @connection_alias = connection_alias
    end

    def start
      # ignore repeated invocation
      return false if @started
      create_profiler_tables
      result = plsql(@connection_alias).dbms_profiler.start_profiler(
        :run_comment => "ruby-plsql-spec #{Time.now.xmlschema}",
        :run_number => nil
      )
      @run_number = result[1][:run_number]
      @coverages = nil
      @started = true
    end

    def self.stop(connection_alias = nil)
      find_or_new(connection_alias).stop
    end

    def stop
      # ignore repeated invocation
      return false unless @started
      plsql(@connection_alias).dbms_profiler.stop_profiler
      @started = false
      true
    end

    def self.cleanup(connection_alias = nil)
      find(connection_alias).cleanup
    end

    def cleanup
      return false if @started
      drop_or_delete_profiler_tables
      true
    end

    def self.find(connection_alias = nil)
      connection_alias ||= :default
      @@coverages[connection_alias]
    end

    def self.report(connection_alias = nil, options = {})
      # if first parameter is Hash then consider it as options and use default connection
      if connection_alias.is_a?(Hash)
        options = connection_alias
        connection_alias = nil
      end
      find(connection_alias).report(options)
    end

    def report(options={})
      # prevent repeated invocation after coverage is reported
      # return if @coverages

      @directory = options.delete(:directory)
      coverage_data(options)
      create_static_files
      read_templates

      # Loop through each database object, evaluating it along with the template
      @coverage_data.keys.sort.each do |schema|
        @coverage_data[schema].keys.sort.each do |object|
          @coverage_data[schema][object].keys.sort.each do |type|
              details_report(schema, object, type)
          end
        end
      end

      index_report
      true
    end

    def coverage_data(options={})
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
      data = {}
      rows = plsql(@connection_alias).select_all <<-EOS
        SELECT u.unit_owner, u.unit_name, u.unit_type, d.line# line_number, d.total_occur
        FROM plsql_profiler_units u, plsql_profiler_data d
        WHERE u.runid = #{@run_number}
          AND u.unit_owner NOT IN (#{quoted_ignore_schemas.join(',')})
          AND u.runid = d.runid
          AND u.unit_number = d.unit_number
          #{like_condition}
        ORDER BY u.unit_owner, u.unit_name, d.line#
      EOS
      rows.each do |row|
        unit_owner, unit_name, unit_type, line_number, total_occur = row
        data[unit_owner] ||= {}
        data[unit_owner][unit_name] ||= {}
        data[unit_owner][unit_name][unit_type] ||= {}
        data[unit_owner][unit_name][unit_type][line_number] = total_occur
      end
      @coverage_data = data
    end

    private

    def self.find_or_new(connection_alias) #:nodoc:
      connection_alias ||= :default
      if @@coverages[connection_alias]
        @@coverages[connection_alias]
      else
        @@coverages[connection_alias] = self.new(connection_alias)
      end
    end

    def create_profiler_tables
      unless PLSQL::Table.find(plsql(@connection_alias), 'plsql_profiler_data')
        proftab_file = File.expand_path('../coverage/proftab.sql', __FILE__)
        File.read(proftab_file).split(";\n").each do |sql|
          if sql =~ /^drop/i
            plsql(@connection_alias).execute sql rescue nil
          elsif sql =~ /^(create|comment)/i
            plsql(@connection_alias).execute sql
          end
        end
        @created_profiler_tables = true
      end
    end

    def drop_or_delete_profiler_tables
      if @created_profiler_tables
        %w(plsql_profiler_data plsql_profiler_units plsql_profiler_runs).each do |table|
          plsql(@connection_alias).execute "DROP TABLE #{table} CASCADE CONSTRAINTS"
        end
        plsql(@connection_alias).execute "DROP SEQUENCE plsql_profiler_runnumber"
      else @run_number
        plsql(@connection_alias).execute <<-SQL, @run_number
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

    def quote_condition_string(string)
      "'#{string.to_s.upcase.gsub(/[^\w\d\$\%\_]/,'')}'"
    end

    def create_static_files
      FileUtils.mkdir_p("#{@directory}")
      %w(coverage.css jquery.min.js jquery.tablesorter.min.js rcov.js).each do |file|
        FileUtils.cp File.expand_path("../coverage/#{file}", __FILE__), "#{@directory}/#{file}"
      end
    end

    def read_templates
      %w(details table_line index).each do |template|
        template_erb = File.read(File.expand_path("../coverage/#{template}.html.erb", __FILE__))
        instance_variable_set("@#{template}_template", ERB.new(template_erb, nil, '><'))
      end

      @table_lines = []
      @total_lines = @analyzed_lines = @executed_lines = 0
    end

    def details_report(schema, object, type)
      # Both PACKAGE and PACKAGE Body share the same name, so
      # in order to get accurate PACKAGE Body coverage reports
      # this module will group by object name and object type.
      object_type = type == 'PACKAGE SPEC' ? 'PACKAGE' : type

      source = plsql(@connection_alias).select_all <<-EOS, schema, object, object_type
        SELECT s.line, s.text
        FROM all_source s
        WHERE s.owner = :owner
          AND s.name = :name
          AND s.type = :type
        ORDER BY s.line
      EOS
      coverage = ((@coverage_data[schema]||{})[object]||{})[type]||{}

      total_lines = source.length
      # return if no access to source of database object
      # or if package body is wrapped
      return if total_lines == 0 || source[0][1] =~ /^\s*PACKAGE BODY .* WRAPPED/i

      # sometimes first PROCEDURE or FUNCTION line is reported as not executed, force ignoring it
      # PACKAGE lines must also be ignored.
      source.each do |line, text|
        if text =~ /^\s*(PROCEDURE|FUNCTION|PACKAGE)/i && coverage[line] == 0
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

      file_name = object_type == 'PACKAGE BODY' ? "#{schema}-#{object} Body.html" : "#{schema}-#{object}.html"
      object_name = object_type == 'PACKAGE BODY' ? "#{schema}.#{object} Body" : "#{schema}.#{object}"

      table_line_html = @table_line_template.result binding
      @table_lines << table_line_html
      html = @details_template.result binding

      File.open("#{@directory}/#{file_name}", "w") do |file|
        file.write html
      end
    end

    def index_report
      schemas = @coverage_data.keys.sort
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

  end
end

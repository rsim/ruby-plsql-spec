# add additional methods to ruby-plsql table operations
module PLSQL
  module TableSpecHelper
    def column_names
      @column_names ||= columns.keys.sort_by{|k| columns[k][:position]}
    end

    def insert_values(*args)
      args.each do |record|
        raise ArgumentError, "record should be Array of values" unless record.is_a?(Array)
        raise ArgumentError, "wrong number of column values" unless record.size == column_names.size
        insert(plsql.connection.arrays_to_hash(column_names, record))
      end
    end
  end
end

PLSQL::Table.class_eval do
  include PLSQL::TableSpecHelper
end

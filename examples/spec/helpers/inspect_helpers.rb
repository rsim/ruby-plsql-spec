# As ruby-plsql returns NUMBER values as BigDecimal values in Ruby then
# change format how they are by default displayed
BigDecimal.class_eval do
  def inspect
    to_s('F')
  end
end

# As ruby-plsql returns NULL as Ruby nil then change nil.inspect to return 'NULL'
NilClass.class_eval do
  def inspect
    'NULL'
  end
end

# NULL looks more like SQL NULL than nil
NULL = nil

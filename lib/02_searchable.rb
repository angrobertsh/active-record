require_relative 'db_connection'
require_relative '01_sql_object'
require 'byebug'

module Searchable
  def where(params)
    k = params.keys
    v = params.values
    l = k.join(" = ? AND ")
    l += " = ?"
    a = DBConnection.execute(<<-SQL, v)
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      #{l}
    SQL
    a.map do |params| new(params) end
  end
end

class SQLObject
  extend Searchable
end

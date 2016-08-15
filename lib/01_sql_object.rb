require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns.class == Array
    all_columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        (#{self.table_name})
    SQL
    @columns = all_columns[0].map{|item| item.to_sym}
    @columns
  end

  def self.finalize!
    make_these_methods = columns

    make_these_methods.each do |method_name|

      define_method "#{method_name.to_s}" do
        attributes[method_name]
      end

      define_method "#{method_name.to_s}=" do |val|
        attributes[method_name] = val
      end

    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    the_name = self.name
    the_name = the_name.split("")
    return_name = []
    return_name << the_name.shift.downcase
    the_name.each do |letter|
      return_name << letter if letter == letter.downcase
      if letter == letter.upcase
        return_name << "_"
        return_name << letter
      end
    end
    return_name << "s"
    return_name.join("")
  end

  def self.all

    rows = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL
    parse_all(rows)

  end

  def self.parse_all(results)
    results.map do |params|
      self.new(params)
    end
  end

  def self.find(id)

    item = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      id = #{id}
    SQL
    parse_all(item)[0]

  end

  def initialize(params = {})
    params.each do |key, v|
      key = key.to_sym
      if self.class.columns.include?(key)
        self.send("#{key}=", v)
      else
        raise "unknown attribute '#{key}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
    @attributes
  end

  def attribute_values
    ret_array = []
    cols = self.class.columns
    cols.each do |col_name|
      ret_array << send(col_name)
    end
    ret_array
  end

  def insert
    columnsa = self.class.columns.drop(1)
    quests = ["?"] * columnsa.length
    cols = columnsa.map { |e| e.to_s  }
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{cols.join(", ")})
      VALUES
        (#{quests.join(",")})
    SQL

    self.id = DBConnection.last_insert_row_id

  end

  def update
    cols = self.class.columns
    cols = cols.map {|col_name| col_name.to_s}
    savestring = ""
    cols.each do |colname|
      savestring += "#{colname} = ?, "
    end
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{savestring[0..savestring.length-3]}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
  end

  def save
    if self.id == nil
      self.insert
    else
      self.update
    end
  end
end

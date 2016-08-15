require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      one = source_options.table_name
      two = through_options.table_name
      three = through_options.foreign_key
      four = source_options.primary_key
      five = through_options.primary_key
      six = self.send(three)
      seven = source_options.foreign_key
      results = DBConnection.execute(<<-SQL, six)
      SELECT
        #{one}.*
      FROM
        #{two}
        JOIN
        #{one}
        ON
        #{two}.#{seven} = #{one}.#{four}
      WHERE
        #{two}.#{five} = ?
      SQL

      source_options.model_class.parse_all(results).first
    end
  end


end

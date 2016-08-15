require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

#
# b.company = {the companies}
# class Board
#   belongs_to :company
#     primary_key: :id,
#     foreign_key: :company_id
#     class_name: 'Company'
# end
#
# c.board = {the boards}
# class Company
#   has_many :boards,
#     primary_key: :id,
#     foreign_key: :company_id,
#     class_name: 'Board'
# end
#

class BelongsToOptions < AssocOptions

  def initialize(name, options = {})
    self.foreign_key = "#{name}_id".to_sym
    self.primary_key = :id
    class_manip = name.to_s
    class_manip[0] = class_manip[0].upcase
    self.class_name = class_manip
    self.foreign_key = options[:foreign_key] unless options[:foreign_key].nil?
    self.primary_key = options[:primary_key] unless options[:primary_key].nil?
    self.class_name = options[:class_name] unless options[:class_name].nil?
  end

end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self_class_name[0] = self_class_name[0].downcase
    self.foreign_key = "#{self_class_name}_id".to_sym
    self.primary_key = :id
    class_manip = name.to_s
    class_manip[0] = class_manip[0].upcase
    self.class_name = class_manip[0..class_manip.length-2]
    self.foreign_key = options[:foreign_key] unless options[:foreign_key].nil?
    self.primary_key = options[:primary_key] unless options[:primary_key].nil?
    self.class_name = options[:class_name] unless options[:class_name].nil?
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
    option = BelongsToOptions.new(name, options)
    define_method(name) do
      f_key = self.send(option.foreign_key)
      primary_key = option.primary_key
      class_name = option.model_class
      class_name.where(primary_key => f_key).first
    end
  end

  def has_many(name, options = {})
    self.assoc_options[name] = HasManyOptions.new(name, self.name, options)
    option = HasManyOptions.new(name, self.name, options)
    define_method(name) do
      p_key = self.send(option.primary_key)
      f_key = option.foreign_key
      class_name = option.model_class
      class_name.where(f_key => p_key)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end

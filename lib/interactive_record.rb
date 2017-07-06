require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_values = DB[:conn].execute(sql)
    column_names = []
    table_values.each do |column|
        column_names << column["name"]
      end
      column_names.compact
  end

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def initialize(options = {})
    options.each do |attribute, value|
      self.send("#{attribute}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def values_for_insert
    values = []
    self.class.column_names.collect do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(attribute = {})
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE #{attribute.keys[0]} = '#{attribute.values[0]}'
    SQL
    DB[:conn].execute(sql)
  end



end

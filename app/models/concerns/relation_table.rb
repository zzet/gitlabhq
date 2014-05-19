module RelationTable
  extend ActiveSupport::Concern

  def relation_table?
    true
  end

  def relations
    self.class.sym_relations.map { |string_relation| self.send(string_relation) }
  end

  module ClassMethods
    attr_reader :sym_relations

    def relations(*relations)
      @sym_relations = relations
    end
  end
end

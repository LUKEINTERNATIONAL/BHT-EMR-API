# frozen_string_literal: true

class VisitAttributeType < RetirableRecord
  self.table_name = :visit_attribute_type
  self.primary_key = :visit_attribute_type_id

  has_many :visit_attributes

  validates_presence_of :name
  validates_uniqueness_of :name
end

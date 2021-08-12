# frozen_string_literal: true

class VisitAttribute < VoidableRecord
  self.table_name = :visit_attribute
  self.primary_key = :visit_attribute_id

  belongs_to :visit
  belongs_to :visit_attribute_type, foreign_key: :attribute_type_id

  validates_presence_of %i[visit visit_attribute_type value_reference]
end

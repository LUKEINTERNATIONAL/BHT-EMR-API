# frozen_string_literal: true

class Visit < VoidableRecord
  self.table_name = :visit
  self.primary_key = :visit_id

  belongs_to :concept, foreign_key: :indication_concept_id, required: false
  belongs_to :location
  belongs_to :visit_type
  belongs_to :patient

  validates_presence_of %i[location patient visit_type]
end

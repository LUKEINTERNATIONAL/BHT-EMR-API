# frozen_string_literal: true

class Visit < VoidableRecord
  self.table_name = :visit
  self.primary_key = :visit_id

  belongs_to :concept, foreign_key: :indication_concept_id, required: false
  belongs_to :location
  belongs_to :visit_type
  belongs_to :patient

  has_many :visit_attributes

  validates_presence_of %i[location patient visit_type]

  def as_json(options = {})
    super(options.merge(
      methods: %i[type]
    ))
  end

  def type
    visit_type.name
  end
end

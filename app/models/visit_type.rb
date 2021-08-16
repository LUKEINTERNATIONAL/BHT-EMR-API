# frozen_string_literal: true

##
# Signals the nature of a patient visit.
#
# This for example may be a normal visit or an external consultation
class VisitType < RetirableRecord
  self.table_name = :visit_type
  self.primary_key = :visit_type_id

  NORMAL_VISIT_NAME = 'Normal visit'

  has_many :visits

  validates_presence_of :name
  validates_uniqueness_of :name

  def self.normal_visit
    VisitType.find_by_name(self::NORMAL_VISIT_NAME)
  end
end

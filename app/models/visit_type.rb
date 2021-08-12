# frozen_string_literal: true

##
# Signals the nature of a patient visit.
#
# This for example may be a normal visit or an external consultation
class VisitType < RetirableRecord
  self.table_name = :visit_type
  self.primary_key = :visit_type_id

  has_many :visits

  validates_presence_of :name
  validates_uniqueness_of :name
end

class VoidableRecord < ApplicationRecord
  self.abstract_class = true

  include Auditable
  include Voidable

  default_scope { where(voided: 0) }

  belongs_to :creator_user, foreign_key: 'creator', class_name: 'User', optional: true

  validates_presence_of :void_reason, if: :voided?
  validates_presence_of :voided_by, if: :voided?
  validates_presence_of :date_voided, if: :voided?
end

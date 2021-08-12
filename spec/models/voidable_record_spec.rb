# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VoidableRecord, type: :model do
  # HACK: VoidableRecord is abstract so we use a known implementation of it for testing
  subject { build(:person, voided: 1, void_reason: 'You suck!', voided_by: User.first.user_id, date_voided: Time.now) }

  context :validations do
    it { should validate_presence_of(:voided_by) }
    it { should validate_presence_of(:date_voided) }
    it { should validate_presence_of(:void_reason) }
  end
end

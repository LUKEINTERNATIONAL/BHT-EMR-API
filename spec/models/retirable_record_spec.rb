# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RetirableRecord, type: :model do
  # HACK: VoidableRecord is abstract so we use a known implementation of it for testing
  subject { build(:concept, retired: 1, retire_reason: 'You suck!', retired_by: User.first.user_id, date_retired: Time.now) }

  context :validations do
    it { should validate_presence_of(:retired_by) }
    it { should validate_presence_of(:date_retired) }
    it { should validate_presence_of(:retire_reason) }
  end
end

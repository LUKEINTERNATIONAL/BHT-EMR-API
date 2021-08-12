# frozen_string_literal: true

require 'rails_helper'

RSpec.describe :visit_attribute, type: :model do
  subject { build(:visit_attribute) }

  context :associations do
    it { should belong_to(:visit).class_name('Visit') }
    it { should belong_to(:visit_attribute_type).class_name('VisitAttributeType') }
  end

  context :validations do
    it { should validate_presence_of(:visit) }
    it { should validate_presence_of(:visit_attribute_type) }
    it { should validate_presence_of(:value_reference) }
  end
end

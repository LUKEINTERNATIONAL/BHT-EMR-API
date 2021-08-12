# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Visit, type: :model do
  subject { build(:visit) }

  context :associations do
    it { should belong_to(:patient).class_name('Patient') }
    it { should belong_to(:visit_type).class_name('VisitType') }
    it { should belong_to(:concept).class_name('Concept').without_validating_presence }
    it { should belong_to(:location).class_name('Location') }
  end

  context :validations do
    it { should validate_presence_of(:patient) }
    it { should validate_presence_of(:visit_type) }
  end
end

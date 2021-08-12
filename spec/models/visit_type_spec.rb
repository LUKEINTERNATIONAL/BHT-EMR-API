# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VisitType, type: :model do
  subject { build(:visit_type) }

  context 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end
end

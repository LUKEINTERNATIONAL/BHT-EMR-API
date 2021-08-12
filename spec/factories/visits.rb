# frozen_string_literal: true

FactoryBot.define do
  factory :visit do
    association :concept
    association :location
    association :patient
    association :visit_type

    creator { User.first.user_id }
  end
end

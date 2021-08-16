# frozen_string_literal: true

FactoryBot.define do
  factory :visit do
    association :concept
    association :location
    association :patient
    association :visit_type

    date_started { Time.now }
    date_stopped { Time.now + 2.hours }

    creator { User.first.user_id }
  end
end

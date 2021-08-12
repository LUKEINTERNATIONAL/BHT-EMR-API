# frozen_string_literal: true

FactoryBot.define do
  factory :visit_attribute do
    association :visit
    association :visit_attribute_type

    creator { User.first.user_id }
    value_reference { Faker::Fantasy::Tolkien.character }
  end
end

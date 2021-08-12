# frozen_string_literal: true

FactoryBot.define do
  factory :visit_attribute_type do
    name { Faker::Ancient.unique.primordial }
    creator { User.first.user_id }
  end
end

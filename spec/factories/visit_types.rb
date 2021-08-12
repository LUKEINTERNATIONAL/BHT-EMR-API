# frozen_string_literal: true

FactoryBot.define do
  factory :visit_type do
    name { Faker::Ancient.unique.titan }
    creator { User.first.user_id }
  end
end

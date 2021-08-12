# frozen_string_literal: true

FactoryBot.define do
  factory :location do
    name { Faker::Fantasy::Tolkien.location }
    creator { User.first.user_id }
  end
end

# frozen_string_literal: true

require 'securerandom'

FactoryBot.define do
  factory :concept_datatype do
    name { SecureRandom.alphanumeric(20) }
    description { SecureRandom.alphanumeric(255) }
    creator { 1 }
    date_created { Time.now }
  end
end
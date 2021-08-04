# frozen_string_literal: true

module PubSub
  module Exceptions
    class PubSubException < StandardError; end

    class UnknownEvent < PubSubException; end

    class UnknownPublisher < PubSubException; end
  end
end

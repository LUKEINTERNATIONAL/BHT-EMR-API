# frozen_string_literal: true

module PubSub
  ##
  # A mixin that provides classes with the ability to publish events and subscribe
  # to events from other peers.
  module Service
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def on(publisher, event, callback = nil, &block)
        callback ||= block

        unless callback
          raise ArgumentError, 'No callback specified, please pass a proc as third argument or define a block'
        end

        broker.add_event_subscription(publisher, event, callback)
        callback
      end

      ##
      # Register/declare an event that a class/module publishes.
      #
      # NOTE: Only registered events may be published by a class.
      def register_event(event)
        broker.register_event(self, event)
      end

      ##
      # Publish a registered event with the given arguments
      #
      # NOTE: The arguments must be serializable to JSON.
      def publish_event(event, *args, **kwargs)
        unless broker.subscriptions.key?(event)
          raise PubSub::Exceptions::UnknownEvent, "Unknown #{self} event: #{event}"
        end

        # TODO: Replace this something that can be customised for various async runners
        #       not just ActiveJob
        ServicePublishEventJob.perform_later(self, event, *args, **kwargs)
      end

      def broker
        PubSub::Broker
      end
    end
  end
end

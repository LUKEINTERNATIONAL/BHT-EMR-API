# frozen_string_literal: true

module PubSub
  ##
  # Manages event subscriptions and broadcasts messages.
  module Broker
    class << self
      ##
      # Declares that publisher will publish this event
      def register_event(publisher, event)
        publisher_events = publishers[publisher] ||= {}
        publisher_events[event] = Set.new
      end

      ##
      # Removes an event from a publishers event list
      def deregister_event(publisher, event)
        events = publisher_events(publisher)
        events.remove(event)
        publishers.remove(publisher) if events.empty?
      end

      def add_event_subscription(publisher, event, callback)
        publisher_event_subscriptions(publisher, event) << callback
      end

      def remove_event_subscription(publisher, event, callback)
        publisher_event_subscriptions(publisher, event).remove(callback)
      end

      def publish_event(publisher, event, *args, **kwargs)
        publisher_event_subscriptions(publisher, event).each do |subscription|
          subscription.call(*args, **kwargs)
        rescue StandardError => e
          logger.error("subscriber failed: #{e.inspect}")
          logger.error(e.backtrace.join("\n"))
        end
      end

      private

      def publishers
        @publishers ||= {} # { publisher: { event: [subscribers, ...] } }
      end

      def publisher_events(publisher)
        publishers.fetch(publisher) do
          raise PubSub::Exceptions::UnknownPublisher, "Publisher '#{publisher}' not found"
        end
      end

      def publisher_event_subscriptions(publisher, event)
        publisher_events(publisher).fetch(event) do
          raise PubSub::Exceptions::UnknownEvent, "Event '#{event}' for publisher '#{publisher}' not found"
        end
      end

      def consumers(publisher, event)
        callbacks = subscriptions.dig(publisher, event)
        raise KeyError, "No event #{event} for publisher #{publisher} found" unless callbacks

        callbacks
      end
    end
  end
end

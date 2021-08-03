# Services

In the EMR-API, we try to centralise all of our business logic in what we call services.
In the most basic case, a service is just a plain old ruby module that groups together methods
that together solve a specific need within a narrow context in the larger EMR domain.
For example, we may have a service that focuses primarily on ART stock management or one
whose goal is to simply handle drug dispensations. A service may be built around a specific model
and simply provide CRUD operations for that model, however in most cases services help in providing
context for operations that cut across multiple models. An example in this case would be a drug
dispensation, this operation involves a patient, an encounter, an order, and a drug at the very
least.

In addition to context, services makes testing functionality easy. Instead of writing an integration
tests that goes through the controller, you can simply write a unit test that focuses solely on
the target operation in the service.

## Events

Services may publish events that other services may listen to and act on asynchronously. This
is an optional feature that services may opt into by including the ServicePubSub mixin and declaring
their events like so:

```ruby

module EncounterService
  class << self
    include ServicePubSub

    register_event :encounter_created

    def create_encounter(**kwargs)
      encounter = Encounter.create!(**kwargs)
      publish_event(:encounter_created, encounter_id: encounter.encounter_id)
    end
  end
end

```

And say you have the following service that maintains a materialized view of the total number
of encounters there are in the database. You can subscibe and react to events from the
EncounterService above as follows:

```ruby
module EncounterCounterService
  class << self
    include ServicePubSub

    on EncounterService, :encounter_created do |params|
      Rails.logger.info("Encounter ##{params[:encounter_id]} created...")
      counter = EncounterCounter.first
      counter.total_encounters += 1
      counter.save!
    end
  end
end
```

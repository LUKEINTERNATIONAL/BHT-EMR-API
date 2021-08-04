# frozen_string_literal: true

module ARTService
  module EncounterEventsHandler
    class << self
      include PubSub::Service

      on EncounterService, :encounter_voided do
        encounter = find_treatment_encounter(encounter_id)
        return unless encounter

        find_treatment_dependent_encounters(encounter).each do |dependent_encounter|
          EncounterService.void(dependent_encounter, "Parent HIV treatment encounter ##{encounter.encounter_id} voided")
        end
      end

      ##
      # Retrieves an HIV Program treatment encounter by its encounter_id
      def find_treatment_encounter(encounter_id)
        Encounter.unscoped
                 .find_by(encounter_id: encounter_id,
                          program: Program.find_by_name('HIV Program'),
                          type: EncounterType.find_by_name('Treatment'))
      end

      def find_treatment_dependent_encounters(treatment_encounter)
        dependent_encounter_types = EncounterType.where(name: %w[Dispensing Appointment])
        # CAVEAT: We are using dates to determine whether encounters are
        # related, might not be the best solution in cases where a visit
        # spans multiple days (what are the odds of this ever happening
        # in ART though?)
        Encounter.where(type: dependent_encounter_types,
                        patient_id: treatment_encounter.patient_id,
                        program: Program.find_by_name('HIV Program'))
                 .where('encounter_datetime >= DATE(:date)
                         AND encounter_datetime <= DATE(:date) + INTERVAL 1 DAY',
                        date: treatment_encounter.encounter_datetime)
      end
    end
  end
end

# frozen_string_literal: true

class EncounterService
  def self.recent_encounter(encounter_type_name:, patient_id:, program_id:, date: nil, start_date: nil)
    start_date ||= Date.strptime('1900-01-01')
    date ||= Date.today
    type = EncounterType.find_by(name: encounter_type_name)

    Encounter.where(type: type, patient_id: patient_id, program_id: program_id)\
             .where('encounter_datetime BETWEEN ? AND ?',
                    *TimeUtils.day_bounds(date))\
             .order(encounter_datetime: :desc)\
             .first
  end

  def create(type:, patient:, program:, encounter_datetime: nil, provider: nil)
    encounter_datetime ||= Time.now
    provider ||= User.current.person

    encounter = find_encounter(type: type, patient: patient, provider: provider,
                               encounter_datetime: encounter_datetime, program: program)

    return encounter if encounter

    Encounter.create(
      type: type, patient: patient, provider: provider,
      encounter_datetime: encounter_datetime, program: program,
      location_id: Location.current.id
    )
  end

  def update(encounter, patient: nil, type: nil, encounter_datetime: nil,
             provider: nil)
    updates = {
      patient: patient, type: type, provider: provider,
      encounter_datetime: encounter_datetime
    }
    updates = updates.keep_if { |_, v| !v.nil? }

    encounter.update(updates)
    encounter
  end

  def find_encounter(type:, patient:, encounter_datetime:, provider:, program:)
    Encounter.where(type: type, patient: patient, program: program)\
             .where('encounter_datetime BETWEEN ? AND ?',
                    *TimeUtils.day_bounds(encounter_datetime))\
             .order(encounter_datetime: :desc)
             .first
  end

  def void(encounter, reason)
    encounter.void(reason)
  end
end

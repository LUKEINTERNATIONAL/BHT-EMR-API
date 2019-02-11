# frozen_string_literal: true

require 'htn_workflow'
require 'set'

module MaternityService
  class WorkflowEngine
    include ModelUtils

    def initialize(program:, patient:, date:)
      @patient = patient
      @program = program
      @date = date
      @activities = load_user_activities
    end

    # Retrieves the next encounter for bound patient
    def next_encounter
      state = INITIAL_STATE
      loop do
        state = next_state state
        break if state == END_STATE

        LOGGER.debug "Loading encounter type: #{state}"
        encounter_type = EncounterType.find_by(name: state)

        return encounter_type if valid_state?(state)
      end

      nil
    end

    private

    LOGGER = Rails.logger

    # Encounter types
    INITIAL_STATE = 0 # Start terminal for encounters graph
    END_STATE = 1 # End terminal for encounters graph
    SOCIAL_HISTORY = 'SOCIAL HISTORY'
    # HIV_RECEPTION = 'HIV RECEPTION'
    # VITALS = 'VITALS'
    # HIV_STAGING = 'HIV STAGING'
    # HIV_CLINIC_CONSULTATION = 'HIV CLINIC CONSULTATION'
    # ART_ADHERENCE = 'ART ADHERENCE'
    # TREATMENT = 'TREATMENT'
    # FAST_TRACK = 'FAST TRACK ASSESMENT' # ASSESMENT[sic] - It's how its named in the db
    # DISPENSING = 'DISPENSING'
    # APPOINTMENT = 'APPOINTMENT'

    # Encounters graph
    ENCOUNTER_SM = {
      INITIAL_STATE => SOCIAL_HISTORY,
      SOCIAL_HISTORY => END_STATE
    }.freeze

    STATE_CONDITIONS = {
        # PATIENT_REGISTRATION => %i[patient_not_registered?],
        # VITALS => %i[patient_checked_in?
        #            patient_not_on_fast_track?
        #            patient_has_not_completed_fast_track_visit?]
    }.freeze

    # Concepts
    PATIENT_PRESENT = 'Patient present'

    def load_user_activities
      activities = user_property('Activities')&.property_value
      encounters = (activities&.split(',') || []).collect do |activity|
        # Re-map activities to encounters
        puts activity
        case activity
        when /Social history/i
          SOCIAL_HISTORY
       
        else
          Rails.logger.warn "Invalid ART activity in user properties: #{activity}"
        end
      end

      Set.new(encounters)
    end

    def next_state(current_state)
      ENCOUNTER_SM[current_state]
    end

    # Check if a relevant encounter of given type exists for given patient.
    #
    # NOTE: By `relevant` above we mean encounters that matter in deciding
    # what encounter the patient should go for in this present time.
    def encounter_exists?(type)
      Encounter.where(type: type, patient: @patient)\
               .where('encounter_datetime BETWEEN ? AND ?', *TimeUtils.day_bounds(@date))\
               .exists?
    end

    def valid_state?(state)
      return false if encounter_exists?(encounter_type(state)) || !art_activity_enabled?(state)

      (STATE_CONDITIONS[state] || []).reduce(true) do |status, condition|
        status && method(condition).call
      end
    end

    def art_activity_enabled?(state)
      # return true if state == FAST_TRACK

      @activities.include?(state)
    end

    # Takes an ART encounter_type and remaps it to a corresponding HTN encounter
    def htn_transform(encounter_type)
      htn_activated = global_property('activate.htn.enhancement')&.property_value&.downcase == 'true'
      return encounter_type unless htn_activated

      htn_workflow.next_htn_encounter(@patient, encounter_type, @date)
    end

    # Checks if patient has checked in today
    #
    # Pre-condition for VITALS encounter
    def patient_checked_in?
      encounter_type = EncounterType.find_by name: HIV_RECEPTION
      encounter = Encounter.where(
        'patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = DATE(?)',
        @patient.patient_id, encounter_type.encounter_type_id, @date
      ).order(encounter_datetime: :desc).first
      raise "Can't check if patient checked in due to missing HIV_RECEPTION" if encounter.nil?

      patient_present_concept = concept PATIENT_PRESENT
      yes_concept = concept 'YES'
      encounter.observations.exists? concept_id: patient_present_concept.concept_id,
                                     value_coded: yes_concept.concept_id
    end

    # Check if patient is not registered
    def patient_not_registered?
      is_registered = Encounter.joins(:type).where(
        'encounter_type.name = ? AND encounter.patient_id = ?',
        HIV_CLINIC_REGISTRATION,
        @patient.patient_id
      ).exists?

      !is_registered
    end

    # Check if patient is not a visiting patient
    def patient_not_visiting?
      patient_type_concept = concept('Type of patient')
      raise '"Type of patient" concept not found' unless patient_type_concept

      visiting_patient_concept = concept('External consultation')
      raise '"External consultation" concept not found' unless visiting_patient_concept

      is_visiting_patient = Observation.where(
        concept: patient_type_concept,
        person: @patient.person,
        value_coded: visiting_patient_concept.concept_id
      ).exists?

      !is_visiting_patient
    end

    # Check if patient is receiving any drugs today
    #
    # Pre-condition for TREATMENT encounter and onwards
    def patient_should_get_treatment?
      prescribe_drugs_concept = concept('Prescribe drugs')
      no_concept = concept('No')
      start_time, end_time = TimeUtils.day_bounds(@date)
      !Observation.where(
        'concept_id = ? AND value_coded = ? AND person_id = ?
         AND obs_datetime BETWEEN ? AND ?',
        prescribe_drugs_concept.concept_id, no_concept.concept_id,
        @patient.patient_id, start_time, end_time
      ).exists?
    end

    # Check if patient has got treatment.
    #
    # Pre-condition for DISPENSING encounter
    def patient_got_treatment?
      encounter_type = EncounterType.find_by name: TREATMENT
      encounter = Encounter.select('encounter_id').where(
        'patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = DATE(?)',
        @patient.patient_id, encounter_type.encounter_type_id, @date
      ).order(encounter_datetime: :desc).first
      !encounter.nil? && encounter.orders.exists?
    end

    # Check if patient received A.R.T.s on previous visit
    def patient_received_art?
      # This code just looks suspect... It does the job and I understand
      # how it does what it does but I just don't trust it somehow.
      # Needs revision, this. Should be a correct or better way of
      # achieving the desired effect.
      arv_ids = Drug.arv_drugs.map(&:drug_id)
      arv_ids_placeholders = "(#{(['?'] * arv_ids.size).join(', ')})"
      Observation.where(
        "person_id = ? AND value_drug in #{arv_ids_placeholders} AND
         obs_datetime < ?",
        @patient.patient_id, *arv_ids, @date.to_date
      ).exists?
    end

    # Checks if patient has not undergone staging before
    def patient_not_already_staged?
      encounter_type = EncounterType.find_by name: 'HIV Staging'
      patient_staged = Encounter.where(
        'patient_id = ? AND encounter_type = ? AND encounter_datetime < ?',
        @patient.patient_id, encounter_type.encounter_type_id, @date.to_date + 1.days
      ).exists?
      !patient_staged
    end

    def dispensing_complete?
      prescription_type = EncounterType.find_by(name: TREATMENT).encounter_type_id
      prescription = Encounter.find_by(encounter_type: prescription_type,
                                       patient_id: @patient.patient_id)

      complete = false

      prescription.orders.each do |order|
        complete = order.drug_order.amount_needed <= 0
        break unless complete
      end

      # TODO: Implement this regimen thingy below...
      # if complete
      #   dispension_completed = patient.set_received_regimen(encounter, prescription)
      # end
      complete
    end

    def assess_for_fast_track?
      assess_for_fast_track_concept = concept('Assess for fast track?')

      # Should we assess fast track?
      Observation.where(
        concept: assess_for_fast_track_concept,
        value_coded: concept('Yes').concept_id,
        person_id: @patient.patient_id
      ).where(
        'obs_datetime BETWEEN ? AND ?', *TimeUtils.day_bounds(@date)
      ).exists?
    end

    # Checks whether current patient is on a fast track visit
    def patient_not_on_fast_track?
      on_fast_track = Observation.where(concept: concept('Fast'), person: @patient.person)\
                                 .where('obs_datetime <= ?', TimeUtils.day_bounds(@date)[1])\
                                 .order(obs_datetime: :desc)\
                                 .first
                                 &.value_coded

      no_concept = concept('No').concept_id
      on_fast_track = on_fast_track ? on_fast_track&.to_i : no_concept

      on_fast_track == no_concept
    end

    # Checks whether fast track visit has been completed
    #
    # This is meant to stop the workflow from restarting after completion of
    # a fast track visit.
    def patient_has_not_completed_fast_track_visit?
      return !@fast_track_completed if @fast_track_completed

      @fast_track_completed = Observation.where(concept: concept('Fast track visit'),
                                                person: @patient.person)\
                                         .where('obs_datetime BETWEEN ? AND ?', *TimeUtils.day_bounds(@date))
                                         .order(obs_datetime: :desc)\
                                         .first
                                         &.value_coded&.to_i == concept('Yes').concept_id

      !@fast_track_completed
    end

    def htn_workflow
      HtnWorkflow.new
    end
  end
end

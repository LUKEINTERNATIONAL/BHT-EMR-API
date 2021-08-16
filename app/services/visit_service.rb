# frozen_string_literal: true

module VisitService
  ##
  # Start a new visit for given patient in specified program
  def self.new_visit(patient, program, date_started: nil, visit_type: nil)
    Visit.create(visit_type: visit_type || VisitType.normal_visit,
                 patient: patient,
                 indicator_concept_id: program.concept_id,
                 date_started: TimeUtils.start_of_day(date_started) || Time.now)
  end

  def self.update_visit(visit, date_stopped:)
    visit.update(TimeUtils.end_of_day(date_stopped) || Time.now)

    visit
  end

  ##
  # Finds all of a patient's visits
  #
  # Parameters:
  #   program - Limit visits to those of this program only
  #   visit_type - Limit visits to this visit_type (defaults to Normal visit)
  def self.find_visits(patient_id: nil, program_name: nil, visit_type_name: nil, date_started: nil, status: nil)
    query_builder = VisitsQueryBuilder.new

    query_builder.filter_by_status(status) if status
    query_builder.filter_by_date_started(date_started) if date_started
    query_builder.filter_by_patient_id(patient_id) if patient_id
    query_builder.filter_by_program_name(program_name) if program_name
    query_builder.filter_by_visit_type_name(visit_type_name) if visit_type_name

    query_builder.query
  end

  class VisitsQueryBuilder
    def initialize(relation = nil)
      @visits = relation || Visit.all
    end

    def filter_by_status(status)
      @visits = case status
                when /open/i then @visits.where(date_stopped: nil)
                when /closed/i then @visits.where.not(date_stopped: nil)
                else raise InvalidParameterError, "Invalid visit status '#{status}' expected 'open' or 'closed'"
                end
    end

    def filter_by_date_started(date)
      date = date.to_date

      @visits = @visits.where(date_started: (date...(date + 1.day)))
    end

    def filter_by_patient_id(patient_id)
      @visits = @visits.where(patient_id: patient_id)
    end

    def filter_by_program_name(name)
      @visits = @visits.joins('INNER JOIN program ON program.concept_id = visit.indication_concept_id')
                       .where('program.name = ?', name)
    end

    def filter_by_visit_type_name(name)
      @visits = @visits.joins(:visit_type).merge(VisitType.where(name: name))
    end

    def query
      @visits
    end
  end
end

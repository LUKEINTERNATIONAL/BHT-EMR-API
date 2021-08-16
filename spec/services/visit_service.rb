# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VisitService do
  subject { VisitService }

  describe :new_visit do
    before(:each) do
      unless VisitType.where(name: VisitType::NORMAL_VISIT_NAME).exists?
        create(:visit_type, name: VisitType::NORMAL_VISIT_NAME)
      end

      Location.current = create(:location)
    end

    it 'creates a visit when all parameters are provided' do
      patient = create(:patient)
      program = create(:program)
      visit_type = create(:visit_type)
      date_started = 10.days.ago

      visit = subject.new_visit(patient.patient_id, program.program_id, visit_type_id: visit_type.visit_type_id,
                                                                        date_started: date_started.to_s)

      expect(visit.visit_id).not_to be_nil
      expect(visit.patient_id).to eq(patient.patient_id)
      expect(visit.concept.concept_id).to eq(program.concept_id)
      expect(visit.date_started.to_date).to eq(date_started.to_date)
    end

    it 'creates a visit of type normal visit when a visit type is not specified' do
      visit = subject.new_visit(create(:patient).patient_id, create(:program).program_id)

      expect(visit.visit_type.name).to eq(VisitType::NORMAL_VISIT_NAME)
    end

    it "creates a visit with date_started `today` when it isn't specified" do
      visit = subject.new_visit(create(:patient).patient_id, create(:program).program_id)

      expect(visit.date_started.to_date).to eq(Date.today)
    end

    it 'raises InvalidParameterError if an invalid program_id is specified' do
      program_id = (Program.last&.program_id || 0) + 1

      expect { subject.new_visit(create(:patient).patient_id, program_id) }
        .to raise_error(InvalidParameterError, /Program ##{program_id} not found/i)
    end

    it 'raise InvalidParameterError if an invalid visit_type_id is specified' do
      visit_type_id = (VisitType.last&.visit_type_id || 0) + 1

      expect { subject.new_visit(create(:patient).patient_id, create(:program).program_id, visit_type_id: visit_type_id) }
        .to raise_error(InvalidParameterError, /Visit type.*not found/i)
    end

    it 'raises InvalidParameterError if an invalid patient_id is specified' do
      patient_id = (Patient.last&.patient_id || 0) + 1

      expect { subject.new_visit(patient_id, create(:program).program_id) }
        .to raise_error(InvalidParameterError, /Patient.*not found/i)
    end
  end

  describe :find_visits do
    it 'retrieves visits by date_started' do
      create_list(:visit, 10, visit_type: create(:visit_type), date_started: 24.hours.from_now)
      visits = create_list(:visit, 5, visit_type: create(:visit_type), date_started: Time.now).collect(&:visit_id)

      result = subject.find_visits(date_started: Date.today.to_s).collect(&:visit_id)
      expect(result).to eq(visits)
    end

    it 'retrieves visits by patient_id' do
      create_list(:visit, 10, visit_type: create(:visit_type))
      patient = create(:patient)
      visits = create_list(:visit, 10, visit_type: create(:visit_type), patient: patient).collect(&:visit_id)

      result = subject.find_visits(patient_id: patient.patient_id).collect(&:visit_id)
      expect(result).to eq(visits)
    end

    it 'retrieves visits by visit_type_name' do
      create_list(:visit, 10, visit_type: create(:visit_type))
      visit_type = create(:visit_type)
      visits = create_list(:visit, 5, visit_type: visit_type).collect(&:visit_id)

      result = subject.find_visits(visit_type_id: visit_type.visit_type_id).collect(&:visit_id)
      expect(result).to eq(visits)
    end

    it 'retrieves visits by status: Open' do
      create_list(:visit, 10, date_started: Time.now,
                              date_stopped: 2.hours.from_now,
                              visit_type: create(:visit_type)) # Control
      visits = create_list(:visit, 5, date_started: Time.now,
                                      date_stopped: nil,
                                      visit_type: create(:visit_type)).collect(&:visit_id)

      result = subject.find_visits(status: 'OPEN').collect(&:visit_id)
      expect(result).to eq(visits)
    end

    it 'retrieves visits by status: Closed' do
      create_list(:visit, 10, date_started: Time.now, date_stopped: nil, visit_type: create(:visit_type)) # Control
      visits = create_list(:visit, 5, date_started: Time.now,
                                      date_stopped: 2.hours.from_now,
                                      visit_type: create(:visit_type)).collect(&:visit_id)

      result = subject.find_visits(status: 'CLOSED').collect(&:visit_id)
      expect(result).to eq(visits)
    end

    it 'raises an error for invalid statuses' do
      expect { subject.find_visits(status: 'FAKE') }.to raise_error(InvalidParameterError, /Invalid visit status/)
    end

    it 'retrieves visits by program_name' do
      create_list(:visit, 10, visit_type: create(:visit_type)) # Our control
      hiv_program = Program.find_by_name('HIV Program')
      created_visits = create_list(:visit, 5, indication_concept_id: hiv_program.concept_id,
                                              visit_type: create(:visit_type)).collect(&:visit_id)

      result = subject.find_visits(program_id: hiv_program.program_id).collect(&:visit_id)
      expect(result).to eq(created_visits)
    end

    it 'retrieves visits by a combination of filters' do
      create_list(:visit, 5, date_stopped: nil)

      patient = create(:patient)
      opd = Program.find_by_name!('OPD Program')

      create(:visit, patient: patient, indication_concept_id: opd.concept_id, date_stopped: Time.now)
      visit = create(:visit, patient: patient, indication_concept_id: opd.concept_id, date_stopped: nil)

      result = subject.find_visits(date_started: visit.date_started.to_date,
                                   status: 'OPEN',
                                   visit_type_id: visit.visit_type_id,
                                   program_id: opd.program_id,
                                   patient_id: patient.patient_id)

      expect(result.size).to eq(1)
      expect(result.first.visit_id).to eq(visit.visit_id)
    end
  end
end

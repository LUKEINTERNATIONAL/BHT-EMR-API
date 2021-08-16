# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VisitService do
  subject { VisitService }

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

      result = subject.find_visits(visit_type_name: visit_type.name).collect(&:visit_id)
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
      hiv_program_concept_id = Program.find_by_name('HIV Program').concept_id
      created_visits = create_list(:visit, 5, indication_concept_id: hiv_program_concept_id,
                                              visit_type: create(:visit_type)).collect(&:visit_id)

      result = subject.find_visits(program_name: 'HIV Program').collect(&:visit_id)
      expect(result).to eq(created_visits)
    end

    it 'retrieves visits by a combination of filters' do
      create_list(:visit, 5, date_stopped: nil)

      patient = create(:patient)
      opd_concept_id = Program.find_by_name('OPD Program').concept_id

      create(:visit, patient: patient, indication_concept_id: opd_concept_id, date_stopped: Time.now)
      visit = create(:visit, patient: patient, indication_concept_id: opd_concept_id, date_stopped: nil)

      result = subject.find_visits(date_started: visit.date_started.to_date,
                                   status: 'OPEN',
                                   visit_type_name: visit.visit_type.name,
                                   program_name: 'OPD Program',
                                   patient_id: patient.patient_id)

      expect(result.size).to eq(1)
      expect(result.first.visit_id).to eq(visit.visit_id)
    end
  end
end

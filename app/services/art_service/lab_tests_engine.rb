# frozen_string_literal: true

require_relative '../nlims'

class ARTService::LabTestsEngine
  include ModelUtils

  def initialize(program:)
    @program = program
  end

  def type(type_id)
    LabTestType.find(type_id)
  end

  def types(search_string:)
    test_types = nlims.test_types

    return test_types unless search_string

    test_types.select { |test_type| test_type.start_with?(search_string) }
  end

  def lab_locations
    nlims.locations
  end

  def labs
    nlims.labs
  end

  def panels(test_type)
    nlims.specimen_types(test_type)
  end

  def results(accession_number)
    LabParameter.joins(:lab_sample)\
                .where('Lab_Sample.AccessionNum = ?', accession_number)\
                .order(Arel.sql('DATE(Lab_Sample.TimeStamp) DESC'))
  end

  def orders_without_results(patient)
    npid = patient.identifier('National id')&.identifier
    raise InvalidParameterError, 'Patient does not have an NPID' unless npid

    nlims.tests_without_results(npid)
  rescue LimsError => e
    return [] if e.message.include?('no test pending for results')

    raise e
  end

  def test_measures(test_name)
    nlims.test_measures(test_name)
  end

  def create_order(encounter:, date:, tests:, **kwargs)
    patient ||= encounter.patient
    date ||= encounter.encounter_datetime

    tests.collect do |test|
      test_type = test['test_type']

      lims_order = nlims.order_test(patient: patient, user: User.current, date: date,
                                    reason: test['reason'], test_type: [test_type],
                                    **kwargs)
      accession_number = lims_order['tracking_number']

      local_order = create_local_order(patient, encounter, date, accession_number)
      create_result_given_observation(local_order) if test_type.match?(/Viral Load/i)
      save_reason_for_test(encounter, local_order, test['reason'])

      { order: local_order, lims_order: lims_order }
    end
  end

  def create_legacy_order(patient, order)
    date_sample_drawn = order['date_sample_drawn'].to_date
    reason_for_test = order['reason_for_test']

    lims_order = nlims.legacy_order_test(patient, order)

    encounter = find_lab_encounter(patient, date_sample_drawn)
    local_order = create_local_order(patient, encounter, date_sample_drawn, lims_order['tracking_number'])
    create_result_given_observation(local_order)
    save_reason_for_test(encounter, local_order, reason_for_test)

    { order: local_order, lims_order: lims_order }
  end

  def find_orders_by_patient(patient, paginate_func: nil)
    local_orders = local_orders(patient)
    local_orders = paginate_func.call(local_orders) if paginate_func
    local_orders.each_with_object([]) do |local_order, collected_orders|
      next unless local_order.accession_number

      orders = find_orders_by_accession_number local_order.accession_number
      collected_orders.push(*orders)
    rescue LimsError => e
      Rails.logger.error("Error finding LIMS order: #{e}")
    end
  end

  def find_orders_by_accession_number(accession_number)
    order = nlims.patient_orders(accession_number)
    begin
      result = nlims.patient_results(accession_number)['results']
    rescue StandardError => e
      raise e unless e.message.include?('results not available')

      result = {}
    end

    [{
      sample_type: order['other']['sample_type'],
      date_ordered: order['other']['date_created'],
      order_location: order['other']['order_location'],
      specimen_status: order['other']['specimen_status'],
      accession_number: accession_number,
      tests: order['tests'].collect do |k, v|
        test_values = result[k]&.collect do |indicator, value|
          { indicator: indicator, value: value }
        end || []

        { test_type: k, test_status: v, test_values: test_values }
      end
    }]
  end

  def save_result(data)
    nlims.update_test(data)
  end

  private

  # Creates an Order in the primary openmrs database
  def create_local_order(patient, encounter, date, accession_number)
    Order.create patient: patient,
                 encounter: encounter,
                 concept: concept('Laboratory tests ordered'),
                 order_type: order_type('Lab'),
                 orderer: User.current.user_id,
                 start_date: date,
                 accession_number: accession_number,
                 provider: User.current
  end

  def save_reason_for_test(encounter, order, reason)
    Observation.create(
      order: order,
      encounter: encounter,
      concept: concept('Reason for test'),
      obs_datetime: encounter.encounter_datetime,
      person: encounter.patient.person,
      value_text: reason
    )
  end

  def create_result_given_observation(order)
    Observation.create(concept_id: ConceptName.find_by(name: 'Result available').concept_id,
                       order_id: order.id,
                       value_coded: ConceptName.find_by(name: 'No').concept_id)
  end

  def find_lab_encounter(patient, date)
    encounter = Encounter.where(patient: patient, program: @program)\
                         .where('encounter_datetime BETWEEN ? AND ?', *TimeUtils.day_bounds(date.to_date))\
                         .last
    return encounter if encounter

    Encounter.create(patient: patient, program: @program, type: encounter_type('Lab'),
                     provider: User.current.person,
                     encounter_datetime: TimeUtils.retro_timestamp(date))
  end

  def local_orders(patient)
    Order.where patient: patient,
                order_type: order_type('Lab'),
                concept: concept('Laboratory tests ordered')
  end

  def nlims
    return @nlims if @nlims

    config = YAML.load_file "#{Rails.root}/config/application.yml"
    @nlims = ::NLims.new config
    @nlims.auth config['lims_username'], config['lims_password']
    @nlims
  end
end

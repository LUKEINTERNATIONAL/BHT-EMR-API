# frozen_string_literal: true

module ARTService
  class DataCleaningTool
    TOOLS = {
      'DATE ENROLLED LESS THAN EARLIEST START DATE' => 'date_enrolled_less_than_earliest_start_date',
      'PRE ART OR UNKNOWN OUTCOMES' => 'pre_art_or_unknown_outcomes',
      'MULTIPLE START REASONS' => 'multiple_start_reasons',
      'MISSING START REASONS' => 'missing_start_reasons',
      'PRESCRIPTION WITHOUT DISPENSATION' => 'prescription_without_dispensation',
      'CLIENTS WITH ENCOUNTERS AFTER DECLARED DEAD' => 'client_with_encounters_after_declared_dead',
      'MALE CLIENTS WITH FEMALE OBS' => 'male_clients_with_female_obs',
      'DOB MORE THAN DATE ENROLLED' => 'dob_more_than_date_enrolled',
      'INCOMPLETE VISITS' => 'incomplete_visit',
      'MISSING DEMOGRAPHICS' => 'incomplete_demographics'
    }.freeze

    def initialize(start_date:, end_date:, tool_name:)
      @start_date = start_date.to_date
      @end_date = end_date.to_date
      @tool_name = tool_name.upcase
    end

    def results
      eval(TOOLS[@tool_name.to_s])
    rescue Exception => e
      "#{e.class}: #{e.message}"
    end

    def self.void_duplicate_npid(identifier)
      ActiveRecord::Base.connection.execute <<~SQL
        UPDATE patient_identifier
        SET voided = 1,
        void_reason = 'Duplicate identifier: #{identifier}',
        voided_by = #{User.current.id},
        date_voided = current_timestamp()
        WHERE identifier = '#{identifier}'
        AND identifier_type = 3
        AND voided = 0
      SQL
    end

    def self.void_unknown_identifiers
      ActiveRecord::Base.connection.execute <<~SQL
        UPDATE patient_identifier
        SET voided = 1,
        void_reason = 'Erroneous identifiers',
        voided_by = #{User.current.id},
        date_voided = current_timestamp()
        WHERE LENGTH(identifier) != 6
        AND LENGTH(identifier) != 13
        AND identifier_type = 3
        AND voided = 0
      SQL
    end

    private

    def incomplete_demographics
      data = ActiveRecord::Base.connection.select_all <<~SQL
        select
          `p`.`patient_id` AS `patient_id`, `pe`.`birthdate`,
          n.given_name, n.family_name, pe.gender, i.identifier arv_number
        from
          ((`patient_program` `p`
          left join `person` `pe` ON ((`pe`.`person_id` = `p`.`patient_id`))
          left join `patient_state` `s` ON ((`p`.`patient_program_id` = `s`.`patient_program_id`)))
          left join `person` ON ((`person`.`person_id` = `p`.`patient_id`)))
          LEFT JOIN patient_identifier i ON i.patient_id = pe.person_id
          AND i.identifier_type = 4 AND i.voided = 0
          LEFT JOIN person_name n ON n.person_id = pe.person_id AND n.voided = 0
        where
          ((`p`.`voided` = 0)
              and (`s`.`voided` = 0)
              and (`p`.`program_id` = 1))
              and (`s`.`start_date`
              between '#{@start_date.strftime('%Y-%m-%d 00:00:00')}'
              and '#{@end_date.strftime('%Y-%m-%d 23:59:59')}'
              and `p`.`patient_id` NOT IN (#{external_clients}))
        group by `p`.`patient_id`
        HAVING NULLIF(birthdate, '') = NULL OR NULLIF(gender,'') = NULL
        OR NULLIF(given_name,'') = NULL OR NULLIF(family_name,'') = NULL
        ORDER BY n.date_created DESC;
      SQL

      return {} if data.blank?

      data
    end

    def dob_more_than_date_enrolled
      data = ActiveRecord::Base.connection.select_all <<~SQL
        select
          `p`.`patient_id` AS `patient_id`, `pe`.`birthdate`,
          cast(patient_date_enrolled(`p`.`patient_id`) as date) AS `date_enrolled`,
          date_antiretrovirals_started(`p`.`patient_id`, min(`s`.`start_date`)) AS `earliest_start_date`,
          n.given_name, n.family_name, pe.gender, i.identifier arv_number
        from
          ((`patient_program` `p`
          left join `person` `pe` ON ((`pe`.`person_id` = `p`.`patient_id`))
          left join `patient_state` `s` ON ((`p`.`patient_program_id` = `s`.`patient_program_id`)))
          left join `person` ON ((`person`.`person_id` = `p`.`patient_id`)))
          LEFT JOIN patient_identifier i ON i.patient_id = pe.person_id
          AND i.identifier_type = 4 AND i.voided = 0
          LEFT JOIN person_name n ON n.person_id = pe.person_id AND n.voided = 0
        where
          ((`p`.`voided` = 0)
              and (`s`.`voided` = 0)
              and (`p`.`program_id` = 1)
              and (`s`.`state` = 7))
              and (`s`.`start_date`
              between '#{@start_date.strftime('%Y-%m-%d 00:00:00')}'
              and '#{@end_date.strftime('%Y-%m-%d 23:59:59')}'
              and `p`.`patient_id` NOT IN (#{external_clients}))
        group by `p`.`patient_id`
        HAVING (DATE(date_enrolled) < DATE(birthdate))
        OR (DATE(earliest_start_date) < DATE(birthdate))
        ORDER BY n.date_created DESC;
      SQL

      return {} if data.blank?

      data
    end

    def date_enrolled_less_than_earliest_start_date
      data = ActiveRecord::Base.connection.select_all <<~SQL
        select
          `p`.`patient_id` AS `patient_id`,
          cast(patient_date_enrolled(`p`.`patient_id`) as date) AS `date_enrolled`,
          date_antiretrovirals_started(`p`.`patient_id`, min(`s`.`start_date`)) AS `earliest_start_date`
        from
          ((`patient_program` `p`
          left join `person` `pe` ON ((`pe`.`person_id` = `p`.`patient_id`))
          left join `patient_state` `s` ON ((`p`.`patient_program_id` = `s`.`patient_program_id`)))
          left join `person` ON ((`person`.`person_id` = `p`.`patient_id`)))
        where
          ((`p`.`voided` = 0)
              and (`s`.`voided` = 0)
              and (`p`.`program_id` = 1)
              and (`s`.`state` = 7))
              and (`s`.`start_date`
              between '#{@start_date.strftime('%Y-%m-%d 00:00:00')}'
              and '#{@end_date.strftime('%Y-%m-%d 23:59:59')}'
              and `p`.`patient_id` NOT IN (#{external_clients}))
        group by `p`.`patient_id`
        HAVING (date_enrolled IS NOT NULL AND earliest_start_date)
        AND DATE(earliest_start_date) > DATE(date_enrolled);
      SQL

      return {} if data.blank?

      patient_ids = data.map { |d| d['patient_id'].to_i }

      data = ActiveRecord::Base.connection.select_all <<~SQL
        SELECT
          p.person_id, i.identifier arv_number, birthdate, gender, death_date,
          n.given_name, n.family_name
        FROM person p
        LEFT JOIN patient_identifier i ON i.patient_id = p.person_id
        AND i.identifier_type = 4 AND i.voided = 0
        LEFT JOIN person_name n ON n.person_id = p.person_id AND n.voided = 0
        WHERE p.person_id IN(#{patient_ids.join(',')})
        GROUP BY p.person_id ORDER BY i.date_created DESC;
      SQL

      organise_data data
    end

    def pre_art_or_unknown_outcomes
      concept_set_id = concept('Antiretroviral drugs').concept_id
      arvs = Drug.joins('INNER JOIN concept_set s ON s.concept_id = drug.concept_id')\
                 .where('s.concept_set = ?', concept_set_id).map(&:drug_id)

      data = ActiveRecord::Base.connection.select_all <<~SQL
        select
          p.patient_id
        from
          ((`patient_program` `p`
          inner join orders o ON o.patient_id = p.patient_id
          inner join drug_order d ON d.order_id = o.order_id
          and d.drug_inventory_id in(#{arvs.join(',')})
          left join `person` `pe` ON ((`pe`.`person_id` = `p`.`patient_id`))
          left join `patient_state` `s` ON ((`p`.`patient_program_id` = `s`.`patient_program_id`)))
          left join `person` ON ((`person`.`person_id` = `p`.`patient_id`)))
        where
          ((`p`.`voided` = 0)
              and (`s`.`voided` = 0)
              and (`d`.`quantity` > 0)
              and (`o`.`voided` = 0)
              and (`p`.`program_id` = 1)
              and (`s`.`state` = 7))
              and (`s`.`start_date`
              between '#{@start_date.strftime('%Y-%m-%d 00:00:00')}'
              and '#{@end_date.strftime('%Y-%m-%d 23:59:59')}'
              and `p`.`patient_id` NOT IN (#{external_clients}))
        group by `p`.`patient_id`
        ORDER BY s.start_date DESC;
      SQL

      return {} if data.blank?

      patient_ids = []
      data_patient_ids = data.collect { |d| d['patient_id'].to_i }

      data_patient_ids.each do |patient_id|
        outcome = ActiveRecord::Base.connection.select_one <<~SQL
          SELECT patient_outcome(#{patient_id}, DATE('#{@end_date}')) outcome;
        SQL

        patient_ids << patient_id if outcome['outcome'].match(/Unknown/i) || outcome['outcome'].match(/Pre/i)
      end

      return {} if patient_ids.blank?

      data = ActiveRecord::Base.connection.select_all <<~SQL
        SELECT
          p.person_id, i.identifier arv_number, birthdate, gender, death_date,
          n.given_name, n.family_name
        FROM person p
        LEFT JOIN patient_identifier i ON i.patient_id = p.person_id
        AND i.identifier_type = 4 AND i.voided = 0
        LEFT JOIN person_name n ON n.person_id = p.person_id AND n.voided = 0
        WHERE p.person_id IN(#{patient_ids.join(',')})
        GROUP BY p.person_id ORDER BY i.date_created DESC;
      SQL

      organise_data data
    end

    def multiple_start_reasons
      concept_id = concept('Reason for ART eligibility').concept_id

      data = ActiveRecord::Base.connection.select_all <<~SQL
        SELECT person_id, count(concept_id) reason
        FROM obs WHERE concept_id=#{concept_id} AND voided = 0
        AND person_id NOT IN (#{external_clients})
        GROUP BY person_id HAVING reason > 1;
      SQL

      return {} if data.blank?

      patient_ids = data.map { |d| d['person_id'].to_i }

      data = ActiveRecord::Base.connection.select_all <<~SQL
        SELECT
          p.person_id, i.identifier arv_number, birthdate, gender, death_date,
          n.given_name, n.family_name
        FROM person p
        LEFT JOIN patient_identifier i ON i.patient_id = p.person_id
        AND i.identifier_type = 4 AND i.voided = 0
        LEFT JOIN person_name n ON n.person_id = p.person_id AND n.voided = 0
        WHERE p.person_id IN(#{patient_ids.join(',')})
        GROUP BY p.person_id ORDER BY i.date_created DESC;
      SQL

      organise_data data
    end

    def missing_start_reasons
      start_date = ActiveRecord::Base.connection.quote(@start_date.to_date)
      end_date = ActiveRecord::Base.connection.quote(@end_date.to_date)

      clients = ActiveRecord::Base.connection.select_all <<~SQL
        SELECT patient_program.patient_id,
               reason_for_art_eligibility.value_coded AS reason_for_art,
               MIN(orders.start_date) AS art_start_date
        FROM patient_program
        INNER JOIN program
          ON program.program_id = patient_program.program_id
          AND program.name = 'HIV Program'
        INNER JOIN orders
          ON orders.patient_id = patient_program.patient_id
          AND orders.start_date < #{end_date}
          AND orders.voided = 0
          AND orders.order_type_id IN (SELECT order_type_id FROM order_type WHERE name = 'Drug order')
          AND orders.concept_id IN (
            SELECT concept_set.concept_id
            FROM concept_set
            INNER JOIN concept_name
              ON concept_name.concept_id = concept_set.concept_set
              AND concept_name.name = 'Antiretroviral drugs'
          )
        INNER JOIN obs AS amount_dispensed
          ON amount_dispensed.order_id = orders.order_id
          AND amount_dispensed.concept_id IN (SELECT concept_id FROM concept_name WHERE name = 'Amount dispensed' AND voided = 0)
          AND amount_dispensed.value_numeric > 0
          AND amount_dispensed.voided = 0
        LEFT JOIN obs AS reason_for_art_eligibility
          ON reason_for_art_eligibility.person_id = patient_program.patient_id
          AND reason_for_art_eligibility.concept_id IN (SELECT concept_id FROM concept_name WHERE name = 'Reason for ART eligibility' AND voided = 0)
          AND reason_for_art_eligibility.voided = 0
        WHERE patient_program.patient_id NOT IN (#{external_clients})
        GROUP BY patient_program.patient_id
        HAVING reason_for_art IS NULL AND art_start_date >= DATE(#{start_date})
      SQL

      patient_ids = clients.map { |p| p['patient_id'].to_i }
      return {} if patient_ids.blank?

      data = ActiveRecord::Base.connection.select_all <<~SQL
        SELECT
          p.person_id, i.identifier arv_number, birthdate, gender, death_date,
          n.given_name, n.family_name
        FROM person p
        LEFT JOIN patient_identifier i ON i.patient_id = p.person_id
        AND i.identifier_type = 4 AND i.voided = 0
        LEFT JOIN person_name n ON n.person_id = p.person_id AND n.voided = 0
        WHERE p.person_id IN(#{patient_ids.join(',')})
        GROUP BY p.person_id ORDER BY i.date_created DESC;
      SQL

      organise_data data
    end

    def prescription_without_dispensation
      start_date = ActiveRecord::Base.connection.quote(@start_date.strftime('%Y-%m-%d 00:00:00'))
      end_date = ActiveRecord::Base.connection.quote(@end_date.strftime('%Y-%m-%d 23:59:59'))

      ActiveRecord::Base.connection.select_all <<~SQL
        SELECT orders.patient_id,
               patient_identifier.identifier AS arv_number,
               birthdate,
               gender,
               start_date AS visit_date,
               quantity,
               given_name,
               family_name
        FROM drug_order
        INNER JOIN orders
          ON orders.order_id = drug_order.order_id
          AND orders.start_date BETWEEN #{start_date} AND #{end_date}
          AND orders.voided = 0
        INNER JOIN encounter
          ON encounter.encounter_id = orders.encounter_id
          AND encounter.program_id = 1
        INNER JOIN person
          ON person.person_id = orders.patient_id
        LEFT JOIN patient_identifier
          ON patient_identifier.patient_id = person.person_id
          AND patient_identifier.identifier_type = 4
          AND patient_identifier.voided = 0
        LEFT JOIN person_name
          ON person_name.person_id = person.person_id
          AND person_name.voided = 0
        LEFT JOIN obs AS dispensation
          ON dispensation.order_id = orders.order_id
          AND dispensation.concept_id IN (SELECT concept_id FROM concept_name WHERE name = 'Amount Dispensed' AND voided = 0)
          AND dispensation.voided = 0
        WHERE (drug_order.quantity IS NULL OR drug_order.quantity <= 0 AND orders.patient_id NOT IN(#{external_clients}))
        GROUP BY DATE(orders.start_date), orders.patient_id
        HAVING COALESCE(SUM(dispensation.value_numeric), 0) <= 0
      SQL
    end

    def client_with_encounters_after_declared_dead
      data = ActiveRecord::Base.connection.select_all <<~SQL
        SELECT person.person_id,
               patient_identifier.identifier AS arv_number,
               person.birthdate,
               person.gender,
               deaths.death_date,
               encounter.encounter_datetime,
               person_name.given_name,
               person_name.family_name
        FROM (
          /* Recorded deaths */
          SELECT patient_program.patient_program_id,
                 patient_program.patient_id,
                 patient_state.start_date AS death_date
          FROM patient_program
          INNER JOIN patient_state
            ON patient_state.patient_program_id = patient_program.patient_program_id
            AND patient_state.voided = 0
            AND patient_state.state IN (
              /* State: Patient Died */
              SELECT program_workflow_state.program_workflow_state_id
              FROM program_workflow_state
              INNER JOIN program_workflow
                ON program_workflow.program_workflow_id = program_workflow_state.program_workflow_id
                AND program_workflow.program_id = 1
                AND program_workflow.retired = 0
              INNER JOIN concept_name
                ON concept_name.concept_id = program_workflow_state.concept_id
                AND concept_name.name = 'Patient Died'
                AND concept_name.voided = 0
              WHERE program_workflow_state.retired = 0
            )
          WHERE patient_program.program_id = 1
            AND patient_program.voided = 0
        ) AS deaths
        INNER JOIN encounter
          /* Need ART encounters only that come after the recorded death above. */
          ON encounter.patient_id = deaths.patient_id
          AND encounter.encounter_datetime >= DATE(deaths.death_date) + INTERVAL 1 DAY
          AND encounter.program_id = 1
          AND encounter.encounter_type NOT IN (
            SELECT encounter_type_id FROM encounter_type WHERE name = 'HIV Reception'
          )
          AND encounter.voided = 0
        INNER JOIN person
          ON person.person_id = deaths.patient_id
        LEFT JOIN patient_identifier
          ON patient_identifier.patient_id = deaths.patient_id
          AND patient_identifier.voided = 0
          AND patient_identifier.identifier_type IN (
            /* ARV Number */
            SELECT patient_identifier_type_id FROM patient_identifier_type
            WHERE name = 'ARV Number' AND retired = 0
          )
        LEFT JOIN person_name
          ON person_name.person_id = deaths.patient_id
          AND person_name.voided = 0
        WHERE person.person_id NOT IN(#{external_clients})
        GROUP BY deaths.patient_id
        ORDER BY patient_identifier.date_created DESC
      SQL

      organise_data(data)
    end

    def male_clients_with_female_obs
      concept_ids = []
      concept_ids << concept('BREASTFEEDING').concept_id
      concept_ids << concept('BREAST FEEDING').concept_id
      concept_ids << concept('PATIENT PREGNANT').concept_id
      concept_ids << concept('Family planning method').concept_id

      data = ActiveRecord::Base.connection.select_all <<~SQL
        SELECT
          p.person_id, given_name, family_name, gender, birthdate,
          i.identifier arv_number
        FROM person p
        INNER JOIN obs ON obs.person_id = p.person_id AND (p.gender != 'F' AND p.gender != 'Female')
        LEFT JOIN patient_identifier i ON i.patient_id = p.person_id
        AND i.identifier_type = 4 AND i.voided = 0
        LEFT JOIN person_name n ON n.person_id = p.person_id
        AND n.voided = 0
        WHERE obs.concept_id IN(#{concept_ids.join(',')})
        OR value_coded IN(#{concept_ids.join(',')})
        AND p.voided = 0 AND obs.voided = 0 and p.person_id NOT IN(#{external_clients})
        GROUP BY p.person_id
        ORDER BY n.date_created DESC;
      SQL

      organise_data data
    end

    def organise_data(data)
      client = []

      (data || []).each do |person|
        client << {
          arv_number: person['arv_number'],
          given_name: person['given_name'],
          family_name: person['family_name'],
          gender: person['gender'],
          birthdate: person['birthdate'],
          patient_id: person['person_id']
        }
      end

      client
    end

    def incomplete_visit
      patient_visit_dates = patient_visits.map { |visit| [visit['patient_id'], visit['visit_date']] }

      return {} if patient_visit_dates.blank?

      incomplete_visits_comp = {}

      patient_visit_dates.each do |patient_id, visit_date|
        patient = Patient.find(patient_id)
        date =  visit_date.to_date
        workflow_engine = ARTService::WorkflowEngine.new(patient: patient, date: date, program: program)
        complete = workflow_engine.next_encounter.blank? ? true : false

        next if complete

        person_details = ActiveRecord::Base.connection.select_one <<~SQL
          SELECT
            n.given_name, n.family_name, p.gender, p.birthdate,
            a.identifier arv_number, i.identifier national_id
          FROM person p
          LEFT JOIN patient_identifier a ON a.patient_id = p.person_id
          AND a.identifier_type = 4 AND a.voided = 0
          LEFT JOIN patient_identifier i ON i.patient_id = p.person_id
          AND i.identifier_type = 3 AND i.voided = 0
          LEFT JOIN person_name n On n.person_id = p.person_id AND n.voided = 0
          WHERE p.person_id = #{patient_id} AND p.voided = 0
          GROUP BY p.person_id ORDER BY i.date_created DESC,
          a.date_created DESC, n.date_created DESC;
        SQL

        if incomplete_visits_comp[patient_id].blank?
          incomplete_visits_comp[patient_id] = {
            given_name: person_details['given_name'],
            family_name: person_details['family_name'],
            gender: person_details['gender'],
            birthdate: person_details['birthdate'],
            arv_number: person_details['arv_number'],
            national_id: person_details['national_id'],
            dates: []
          }
        end
        incomplete_visits_comp[patient_id][:dates] << visit_date.to_date
      end

      incomplete_visits_comp
    end

    def concept(name)
      ConceptName.find_by_name(name)
    end

    def program
      @program ||= Program.find_by_name!('HIV Program')
    end

    ##
    # Returns all non-refill (external consultation) visits patients have had in a given time period
    def patient_visits
      ActiveRecord::Base.connection.select_all <<~SQL
        SELECT encounter.patient_id, DATE(encounter.encounter_datetime) AS visit_date
        FROM encounter
        INNER JOIN (
            SELECT patient_id, MAX(encounter_datetime) AS encounter_datetime
            FROM encounter
            WHERE encounter_type = #{EncounterType.find_by_name!('Registration').encounter_type_id}
              AND encounter_datetime <= DATE(#{ActiveRecord::Base.connection.quote(@end_date)}) + INTERVAL 1 DAY
              AND voided = 0
            GROUP BY patient_id
        ) AS max_registration_encounter
          ON max_registration_encounter.encounter_datetime <= encounter.encounter_datetime
          AND max_registration_encounter.patient_id = encounter.patient_id
        WHERE encounter.encounter_datetime >= DATE(#{ActiveRecord::Base.connection.quote(@start_date)})
          AND encounter.encounter_datetime < DATE(#{ActiveRecord::Base.connection.quote(@end_date)}) + INTERVAL 1 DAY
          AND encounter.encounter_type NOT IN (
            SELECT encounter_type_id FROM encounter_type WHERE name IN ('EXIT FROM HIV CARE', 'LAB', 'LAB ORDERS', 'LAB RESULTS')
          )
          AND program_id = #{Program.find_by_name!('HIV Program').program_id}
          AND voided = 0
        GROUP BY encounter.patient_id, DATE(encounter.encounter_datetime)
      SQL
    end

    # rubocop:disable Metrics/MethodLength
    # Method to fetch all external and drug refills from the system
    def external_clients
      property = GlobalProperty.find_by(property: 'can.remove.external.and.drug.refills.from.data.cleaning')
      return 0 if property.blank? || property&.property_value == 'false'

      end_date = ActiveRecord::Base.connection.quote(@end_date.to_date)
      clients = ActiveRecord::Base.connection.select_all <<~SQL
        SELECT obs.person_id FROM obs,
        (SELECT person_id, Max(obs_datetime) AS obs_datetime, concept_id FROM obs
        WHERE concept_id IN (SELECT concept_id FROM concept_name WHERE name = 'Type of patient' AND voided = 0)
        AND DATE(obs_datetime) <= #{end_date}
        AND voided = 0
        GROUP BY person_id) latest_record
        WHERE obs.person_id = latest_record.person_id
        AND obs.concept_id = latest_record.concept_id
        AND obs.obs_datetime = latest_record.obs_datetime
        AND obs.value_coded IN (SELECT concept_id FROM concept_name WHERE name = 'Drug refill' || name = 'External consultation')
        AND obs.voided = 0
      SQL
      clients.map { |record| record['person_id'] }.push(0).join(',')
    end
    # rubocop:enable Metrics/MethodLength
  end
end

# frozen_string_literal: true

module ARTService
  module Reports
    class CohortDisaggregated
      def initialize(name:, type:, start_date:, end_date:, rebuild:)
        @name = name
        @type = type
        @start_date = start_date
        @end_date = end_date
        @rebuild = rebuild
      end

      def find_report
        build_report
      end

      def build_report
        builder = CohortDisaggregatedBuilder.new
        builder.build(nil, @start_date, @end_date)
      end

      def initialize_disaggregated

        ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS temp_disaggregated')
        
        ActiveRecord::Base.connection.execute(
          'CREATE TABLE IF NOT EXISTS temp_disaggregated (
             patient_id INTEGER PRIMARY KEY,
             age_group VARCHAR(20),
             maternal_status VARCHAR(10),
             given_ipt INT(1),
             screened_for_tb INT(1)
          ) ENGINE=MEMORY;'
        )

        return {temp_disaggregated: 'created'}
      end

      def disaggregated(quarter, age_group)

        temp_outcome_table = 'temp_patient_outcomes'

        if quarter == 'pepfar'
          start_date = @start_date
          end_date = @end_date
          temp_outcome_table = 'temp_pepfar_patient_outcomes'

          begin
            records = ActiveRecord::Base.connection.select_one('SELECT count(*) rec_count FROM temp_pepfar_patient_outcomes;')
            if records['rec_count'].to_i < 1
              @rebuild = true
            end
          rescue 
            initialize_disaggregated
            create_mysql_pepfar_current_defaulter
            create_mysql_pepfar_current_outcome
            rebuild_outcomes 
          end

          if @rebuild
            initialize_disaggregated
            create_mysql_pepfar_current_defaulter
            create_mysql_pepfar_current_outcome
            rebuild_outcomes 
          end


        else
          start_date, end_date = generate_start_date_and_end_date(quarter)
        end

        tmp = get_age_groups(age_group, start_date, end_date, temp_outcome_table)

        on_art = []
        all_clients = []
        all_clients_outcomes = {}

        (tmp || []).each do |pat|
          patient_id = pat['patient_id'].to_i
          outcome = pat['outcome']

          on_art << patient_id if outcome == 'On antiretrovirals'
          all_clients << patient_id
          all_clients_outcomes[patient_id] = outcome
        end

        list = {}
        
        if all_clients.blank? && (age_group == 'Breastfeeding' || age_group == 'Pregnant')
          list[age_group] = {}
          list[age_group]['F'] = {
            tx_new: 0, tx_curr: 0,
            tx_screened_for_tb: 0,
            tx_given_ipt: 0
          }
          return list
        elsif all_clients.blank?
           return {}
        end

        if age_group.match(/year|month/i)  
          big_insert tmp, age_group
        end

        (tmp || []).each do |r|
          gender = r['gender'].first
          patient_id = r['patient_id'].to_i
          tx_new, tx_curr, tx_given_ipt, tx_screened_for_tb = get_numbers(r, age_group, start_date, end_date, all_clients_outcomes)

          list[age_group] = {} if list[age_group].blank?

          list[age_group][gender] = {
            tx_new: 0, tx_curr: 0,
            tx_screened_for_tb: 0,
            tx_given_ipt: 0
          } if list[age_group][gender].blank?


          list[age_group][gender][:tx_new] += tx_new
          list[age_group][gender][:tx_curr] += tx_curr
          list[age_group][gender][:tx_given_ipt] += tx_given_ipt
          list[age_group][gender][:tx_screened_for_tb] += tx_screened_for_tb

          date_enrolled  = r['date_enrolled'].to_date

          if gender == 'F' && all_clients_outcomes[patient_id] == 'On antiretrovirals'
            insert_female_maternal_status(patient_id, age_group, end_date)
          elsif gender == 'F' && (date_enrolled >= start_date && date_enrolled <= end_date) 
            insert_female_maternal_status(patient_id, age_group, end_date)
          end

        end

        return list
      end

      def generate_start_date_and_end_date(quarter)
        quarter, quarter_year = quarter.humanize.split(" ")

        quarter_start_dates = [
          "#{quarter_year}-01-01".to_date,
          "#{quarter_year}-04-01".to_date,
          "#{quarter_year}-07-01".to_date,
          "#{quarter_year}-10-01".to_date
        ]

        quarter_end_dates = [
          "#{quarter_year}-03-31".to_date,
          "#{quarter_year}-06-30".to_date,
          "#{quarter_year}-09-30".to_date,
          "#{quarter_year}-12-31".to_date
        ]

        current_quarter   = (quarter.match(/\d+/).to_s.to_i - 1)
        quarter_beginning = quarter_start_dates[current_quarter]
        quarter_ending    = quarter_end_dates[current_quarter]

        date_range = [quarter_beginning, quarter_ending]
      end

      def screened_for_tb(my_patient_id, age_group, start_date, end_date)
        data = ActiveRecord::Base.connection.select_one <<EOF
        SELECT patient_screened_for_tb(#{my_patient_id}, 
          '#{start_date.to_date}', '#{end_date.to_date}') AS screened;
EOF

        screened = data['screened'].to_i

        ActiveRecord::Base.connection.execute <<EOF
        UPDATE temp_disaggregated SET screened_for_tb =  #{screened}, 
        age_group = '#{age_group}'
        WHERE patient_id = #{my_patient_id};
EOF

        return screened
      end

      def given_ipt(my_patient_id, age_group, start_date, end_date)
        
        data = ActiveRecord::Base.connection.select_one <<EOF
        SELECT patient_given_ipt(#{my_patient_id}, 
          '#{start_date.to_date}', '#{end_date.to_date}') AS given;
EOF

        given = data['given'].to_i

        ActiveRecord::Base.connection.execute <<EOF
        UPDATE temp_disaggregated SET given_ipt =  #{given} ,
        age_group = '#{age_group}'
        WHERE patient_id = #{my_patient_id};
EOF
      
        return given
      end

      def get_numbers(data, age_group, start_date, end_date, outcomes)
        patient_id = data['patient_id'].to_i
        tx_new = 0
        tx_curr = 0
        tx_screened_for_tb = 0
        tx_given_ipt  = 0
        outcome = outcomes[patient_id]

        date_enrolled  = data['date_enrolled'].to_date
        earliest_start_date  = data['earliest_start_date'].to_date rescue nil

        if date_enrolled >= start_date && date_enrolled <= end_date
          if date_enrolled == earliest_start_date
            tx_new = 1
          end unless earliest_start_date.blank?
          
          if outcome == 'On antiretrovirals'
            tx_curr = 1
          end
        elsif outcome == 'On antiretrovirals'
          tx_curr = 1
        end

        if outcome == 'On antiretrovirals'
          #tx_screened_for_tb = screened_for_tb(patient_id, age_group, date_enrolled, end_date)
          #tx_given_ipt = given_ipt(patient_id, age_group, date_enrolled, end_date)
        end

        return [tx_new, tx_curr, tx_given_ipt, tx_screened_for_tb]
      end

      def get_age_groups(age_group, start_date, end_date, temp_outcome_table)
        if age_group != 'Pregnant' && age_group != 'FNP' && age_group != 'Not pregnant' && age_group != 'Breastfeeding'
         
          results = ActiveRecord::Base.connection.select_all <<EOF
            SELECT 
            e.*,  cohort_disaggregated_age_group(DATE(e.birthdate), DATE('#{end_date}')) AS age_group,
            t2.cum_outcome AS outcome
            FROM temp_earliest_start_date e 
            INNER JOIN #{temp_outcome_table} t2 ON t2.patient_id = e.patient_id
            GROUP BY e.patient_id HAVING age_group = '#{age_group}';
EOF

        elsif age_group == 'Pregnant'
          create_mysql_female_maternal_status
          results = ActiveRecord::Base.connection.select_all <<EOF
            SELECT 
              e.*, maternal_status AS mstatus,
              t3.cum_outcome AS outcome
            FROM temp_earliest_start_date e 
            INNER JOIN temp_disaggregated t2 ON t2.patient_id = e.patient_id
            INNER JOIN #{temp_outcome_table} t3 ON t3.patient_id = e.patient_id
            WHERE maternal_status = 'FP'
            GROUP BY e.patient_id;
EOF

        elsif age_group == 'Breastfeeding'
          create_mysql_female_maternal_status
          results = ActiveRecord::Base.connection.select_all <<EOF
            SELECT 
              e.*, maternal_status AS mstatus,
              t3.cum_outcome AS outcome
            FROM temp_earliest_start_date e 
            INNER JOIN temp_disaggregated t2 ON t2.patient_id = e.patient_id
            INNER JOIN #{temp_outcome_table} t3 ON t3.patient_id = e.patient_id
            WHERE maternal_status = 'FBf'
            GROUP BY e.patient_id;
EOF

        elsif age_group == 'FNP'
          create_mysql_female_maternal_status
          results = ActiveRecord::Base.connection.select_all <<EOF
            SELECT 
              e.*, maternal_status AS mstatus,
              t3.cum_outcome AS outcome
            FROM temp_earliest_start_date e 
            INNER JOIN temp_disaggregated t2 ON t2.patient_id = e.patient_id
            INNER JOIN #{temp_outcome_table} t3 ON t3.patient_id = e.patient_id
            WHERE maternal_status = 'FNP'
            GROUP BY e.patient_id;
EOF

        end

        return results
        
      end

      def create_mysql_female_maternal_status
        ActiveRecord::Base.connection.execute <<EOF
        DROP FUNCTION IF EXISTS female_maternal_status;
EOF

        ActiveRecord::Base.connection.execute <<EOF
CREATE FUNCTION female_maternal_status(my_patient_id int, end_datetime datetime) RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN

DECLARE breastfeeding_date DATETIME;
DECLARE pregnant_date DATETIME;
DECLARE maternal_status VARCHAR(20);
DECLARE obs_value_coded INT(11);


SET @reason_for_starting = (SELECT concept_id FROM concept_name WHERE name = 'Reason for ART eligibility' LIMIT 1);

SET @pregnant_concepts := (SELECT GROUP_CONCAT(concept_id) FROM concept_name WHERE name IN('Is patient pregnant?','Patient pregnant'));
SET @breastfeeding_concept := (SELECT GROUP_CONCAT(concept_id) FROM concept_name WHERE name = 'Breastfeeding');

SET pregnant_date = (SELECT MAX(obs_datetime) FROM obs WHERE concept_id IN(@pregnant_concepts) AND voided = 0 AND person_id = my_patient_id AND obs_datetime <= end_datetime);
SET breastfeeding_date = (SELECT MAX(obs_datetime) FROM obs WHERE concept_id IN(@breastfeeding_concept) AND voided = 0 AND person_id = my_patient_id AND obs_datetime <= end_datetime);

IF pregnant_date IS NULL THEN
  SET pregnant_date = (SELECT MAX(obs_datetime) FROM obs WHERE concept_id = @reason_for_starting AND voided = 0 AND person_id = my_patient_id AND obs_datetime <= end_datetime AND value_coded IN(1755));
END IF;

IF breastfeeding_date IS NULL THEN
  SET breastfeeding_date = (SELECT MAX(obs_datetime) FROM obs WHERE concept_id = @reason_for_starting AND voided = 0 AND person_id = my_patient_id AND obs_datetime <= end_datetime AND value_coded IN(834,5632));
END IF;

IF pregnant_date IS NULL AND breastfeeding_date IS NULL THEN SET maternal_status = "FNP";
ELSEIF pregnant_date IS NOT NULL AND breastfeeding_date IS NOT NULL THEN SET maternal_status = "Unknown";
ELSEIF pregnant_date IS NULL AND breastfeeding_date IS NOT NULL THEN SET maternal_status = "Check BF";
ELSEIF pregnant_date IS NOT NULL AND breastfeeding_date IS NULL THEN SET maternal_status = "Check FP";
END IF;

IF maternal_status = 'Unknown' THEN
  
  IF breastfeeding_date <= pregnant_date THEN  
    SET obs_value_coded = (SELECT value_coded FROM obs WHERE concept_id IN(@pregnant_concepts) AND voided = 0 AND person_id = my_patient_id AND obs_datetime = pregnant_date LIMIT 1);
    IF obs_value_coded = 1065 THEN SET maternal_status = 'FP';  
    ELSEIF obs_value_coded = 1066 THEN SET maternal_status = 'FNP';
    END IF;  
  END IF;
  
  IF breastfeeding_date > pregnant_date THEN  
    SET obs_value_coded = (SELECT value_coded FROM obs WHERE concept_id IN(@breastfeeding_concept) AND voided = 0 AND person_id = my_patient_id AND obs_datetime = breastfeeding_date LIMIT 1);
    IF obs_value_coded = 1065 THEN SET maternal_status = 'FBf';  
    ELSEIF obs_value_coded = 1066 THEN SET maternal_status = 'FNP';
    END IF;  
  END IF;
  
  IF DATE(breastfeeding_date) = DATE(pregnant_date) AND maternal_status = 'FNP' THEN  
    SET obs_value_coded = (SELECT value_coded FROM obs WHERE concept_id IN(@breastfeeding_concept) AND voided = 0 AND person_id = my_patient_id AND obs_datetime = breastfeeding_date LIMIT 1);
    IF obs_value_coded = 1065 THEN SET maternal_status = 'FBf';
    ELSEIF obs_value_coded = 1066 THEN SET maternal_status = 'FNP';
    END IF;  
  END IF;  
END IF;

IF maternal_status = 'Check FP' THEN

  SET obs_value_coded = (SELECT value_coded FROM obs WHERE concept_id IN(@pregnant_concepts) AND voided = 0 AND person_id = my_patient_id AND obs_datetime = pregnant_date LIMIT 1);
  IF obs_value_coded = 1065 THEN SET maternal_status = 'FP';  
  ELSEIF obs_value_coded = 1066 THEN SET maternal_status = 'FNP';
  END IF;  

  IF obs_value_coded IS NULL THEN
    SET obs_value_coded = (SELECT GROUP_CONCAT(value_coded) FROM obs WHERE concept_id IN(7563) AND voided = 0 AND person_id = my_patient_id AND obs_datetime = pregnant_date);
    IF obs_value_coded IN(1755) THEN SET maternal_status = 'FP';  
    END IF;  
  END IF;

  IF maternal_status = 'Check FP' THEN SET maternal_status = 'FNP';
  END IF;
END IF;

IF maternal_status = 'Check BF' THEN

  SET obs_value_coded = (SELECT value_coded FROM obs WHERE concept_id IN(@breastfeeding_concept) AND voided = 0 AND person_id = my_patient_id AND obs_datetime = breastfeeding_date LIMIT 1);
  IF obs_value_coded = 1065 THEN SET maternal_status = 'FBf';  
  ELSEIF obs_value_coded = 1066 THEN SET maternal_status = 'FNP';
  END IF;  

  IF obs_value_coded IS NULL THEN
    SET obs_value_coded = (SELECT GROUP_CONCAT(value_coded) FROM obs WHERE concept_id IN(7563) AND voided = 0 AND person_id = my_patient_id AND obs_datetime = breastfeeding_date);
    IF obs_value_coded IN(834,5632) THEN SET maternal_status = 'FBf';  
    END IF;  
  END IF;

  IF maternal_status = 'Check BF' THEN SET maternal_status = 'FNP';
  END IF;
END IF;



RETURN maternal_status;
END;
EOF

      end
  
      def rebuild_outcomes
        ActiveRecord::Base.connection.execute(
          'DROP TABLE IF EXISTS `temp_pepfar_patient_outcomes`'
        )

        ActiveRecord::Base.connection.execute(
          "CREATE TABLE temp_pepfar_patient_outcomes ENGINE=MEMORY AS (
            SELECT e.patient_id, patient_pepfar_outcome(e.patient_id, '#{@end_date.to_date} 23:59:59') AS cum_outcome
            FROM temp_earliest_start_date e WHERE e.date_enrolled <= '#{@end_date.to_date}'
          )"
        )

        ActiveRecord::Base.connection.execute(
          'ALTER TABLE temp_pepfar_patient_outcomes
           ADD INDEX patient_id_index (patient_id)'
        )

        ActiveRecord::Base.connection.execute(
          'ALTER TABLE temp_pepfar_patient_outcomes
           ADD INDEX cum_outcome_index (cum_outcome)'
        )

        ActiveRecord::Base.connection.execute(
          'ALTER TABLE temp_pepfar_patient_outcomes
           ADD INDEX patient_id_cum_outcome_index (patient_id, cum_outcome)'
        )

      end

      def create_mysql_pepfar_current_defaulter
        ActiveRecord::Base.connection.execute <<EOF
        DROP FUNCTION IF EXISTS current_pepfar_defaulter;
EOF

        ActiveRecord::Base.connection.execute <<EOF
CREATE FUNCTION current_pepfar_defaulter(my_patient_id INT, my_end_date DATETIME) RETURNS int(1)
DETERMINISTIC
BEGIN

  DECLARE done INT DEFAULT FALSE;
  DECLARE my_start_date, my_expiry_date, my_obs_datetime DATETIME;
  DECLARE my_daily_dose, my_quantity, my_pill_count, my_total_text, my_total_numeric DECIMAL;
  DECLARE my_drug_id, flag INT;

  DECLARE cur1 CURSOR FOR SELECT d.drug_inventory_id, o.start_date, d.equivalent_daily_dose daily_dose, d.quantity, o.start_date FROM drug_order d
    INNER JOIN arv_drug ad ON d.drug_inventory_id = ad.drug_id
    INNER JOIN orders o ON d.order_id = o.order_id
      AND d.quantity > 0
      AND o.voided = 0
      AND o.start_date <= my_end_date
      AND o.patient_id = my_patient_id;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  SELECT MAX(o.start_date) INTO @obs_datetime FROM drug_order d
    INNER JOIN arv_drug ad ON d.drug_inventory_id = ad.drug_id
    INNER JOIN orders o ON d.order_id = o.order_id
      AND d.quantity > 0
      AND o.voided = 0
      AND o.start_date <= my_end_date
      AND o.patient_id = my_patient_id
    GROUP BY o.patient_id;

  OPEN cur1;

  SET flag = 0;

  read_loop: LOOP
    FETCH cur1 INTO my_drug_id, my_start_date, my_daily_dose, my_quantity, my_obs_datetime;

    IF done THEN
      CLOSE cur1;
      LEAVE read_loop;
    END IF;

    IF DATE(my_obs_datetime) = DATE(@obs_datetime) THEN

      IF my_daily_dose = 0 OR LENGTH(my_daily_dose) < 1 OR my_daily_dose IS NULL THEN
        SET my_daily_dose = 1;
      END IF;

            SET my_pill_count = drug_pill_count(my_patient_id, my_drug_id, my_obs_datetime);

            SET @expiry_date = ADDDATE(DATE_SUB(my_start_date, INTERVAL 2 DAY), ((my_quantity + my_pill_count)/my_daily_dose));

      IF my_expiry_date IS NULL THEN
        SET my_expiry_date = @expiry_date;
      END IF;

      IF @expiry_date < my_expiry_date THEN
        SET my_expiry_date = @expiry_date;
            END IF;
        END IF;
    END LOOP;

    IF TIMESTAMPDIFF(day, my_expiry_date, my_end_date) > 30 THEN
        SET flag = 1;
    END IF;

  RETURN flag;
  END;
EOF

      
      end

      def create_mysql_pepfar_current_outcome
        ActiveRecord::Base.connection.execute <<EOF
        DROP FUNCTION IF EXISTS patient_pepfar_outcome;
EOF

        ActiveRecord::Base.connection.execute <<EOF
CREATE FUNCTION patient_pepfar_outcome(patient_id INT, visit_date date) RETURNS varchar(25)
DETERMINISTIC
BEGIN

DECLARE set_program_id INT;
DECLARE set_patient_state INT;
DECLARE set_outcome varchar(25);
DECLARE set_date_started date;
DECLARE set_patient_state_died INT;
DECLARE set_died_concept_id INT;
DECLARE set_timestamp DATETIME;
DECLARE dispensed_quantity INT;

SET set_timestamp = TIMESTAMP(CONCAT(DATE(visit_date), ' ', '23:59:59'));
SET set_program_id = (SELECT program_id FROM program WHERE name ="HIV PROGRAM" LIMIT 1);

SET set_patient_state = (SELECT state FROM `patient_state` INNER JOIN patient_program p ON p.patient_program_id = patient_state.patient_program_id AND p.program_id = set_program_id WHERE (patient_state.voided = 0 AND p.voided = 0 AND p.program_id = program_id AND DATE(start_date) <= visit_date AND p.patient_id = patient_id) AND (patient_state.voided = 0) ORDER BY start_date DESC, patient_state.patient_state_id DESC, patient_state.date_created DESC LIMIT 1);

IF set_patient_state = 1 THEN
  SET set_patient_state = current_pepfar_defaulter(patient_id, set_timestamp);

  IF set_patient_state = 1 THEN
    SET set_outcome = 'Defaulted';
  ELSE
    SET set_outcome = 'Pre-ART (Continue)';
  END IF;
END IF;

IF set_patient_state = 2   THEN
  SET set_outcome = 'Patient transferred out';
END IF;

IF set_patient_state = 3 OR set_patient_state = 127 THEN
  SET set_outcome = 'Patient died';
END IF;


IF set_patient_state != 3 AND set_patient_state != 127 THEN
  SET set_patient_state_died = (SELECT state FROM `patient_state` INNER JOIN patient_program p ON p.patient_program_id = patient_state.patient_program_id AND p.program_id = set_program_id WHERE (patient_state.voided = 0 AND p.voided = 0 AND p.program_id = program_id AND DATE(start_date) <= visit_date AND p.patient_id = patient_id) AND (patient_state.voided = 0) AND state = 3 ORDER BY patient_state.patient_state_id DESC, patient_state.date_created DESC, start_date DESC LIMIT 1);

  SET set_died_concept_id = (SELECT concept_id FROM concept_name WHERE name = 'Patient died' LIMIT 1);

  IF set_patient_state_died IN(SELECT program_workflow_state_id FROM program_workflow_state WHERE concept_id = set_died_concept_id AND retired = 0) THEN
    SET set_outcome = 'Patient died';
    SET set_patient_state = 3;
  END IF;
END IF;



IF set_patient_state = 6 THEN
  SET set_outcome = 'Treatment stopped';
END IF;

IF set_patient_state = 7 THEN
  SET set_patient_state = current_pepfar_defaulter(patient_id, set_timestamp);

  IF set_patient_state = 1 THEN
    SET set_outcome = 'Defaulted';
  END IF;

  IF set_patient_state = 0 THEN

    SET dispensed_quantity = (SELECT d.quantity
      FROM orders o
      INNER JOIN drug_order d ON d.order_id = o.order_id
      INNER JOIN drug ON drug.drug_id = d.drug_inventory_id
      WHERE o.patient_id = patient_id AND d.drug_inventory_id IN(
        SELECT DISTINCT(drug_id) FROM drug WHERE
        concept_id IN(SELECT concept_id FROM concept_set WHERE concept_set = 1085)
    ) AND DATE(o.start_date) <= visit_date AND d.quantity > 0 ORDER BY start_date DESC LIMIT 1);

    IF dispensed_quantity > 0 THEN
      SET set_outcome = 'On antiretrovirals';
    END IF;
  END IF;
END IF;

IF set_outcome IS NULL THEN
  SET set_patient_state = current_pepfar_defaulter(patient_id, set_timestamp);

  IF set_patient_state = 1 THEN
    SET set_outcome = 'Defaulted';
  END IF;

  IF set_outcome IS NULL THEN
    SET set_outcome = 'Unknown';
  END IF;

END IF;



RETURN set_outcome;
END;
EOF
      end

      def insert_female_maternal_status(patient_id, age_group, end_date)
        encounter_types = []
        encounter_types << EncounterType.find_by_name('HIV CLINIC CONSULTATION').encounter_type_id
        encounter_types << EncounterType.find_by_name('HIV STAGING').encounter_type_id

        pregnant_concepts = []
        pregnant_concepts << ConceptName.find_by_name('Is patient pregnant?').concept_id
        pregnant_concepts << ConceptName.find_by_name('patient pregnant').concept_id

        results = ActiveRecord::Base.connection.select_all(
          "SELECT person_id FROM obs obs
            INNER JOIN encounter enc ON enc.encounter_id = obs.encounter_id AND enc.voided = 0
          WHERE obs.person_id = #{patient_id}
          AND obs.obs_datetime <= '#{end_date.to_date.strftime('%Y-%m-%d 23:59:59')}'
          AND obs.concept_id IN(#{pregnant_concepts.join(',')}) AND obs.value_coded = '1065'
          AND obs.voided = 0 AND enc.encounter_type IN(#{encounter_types.join(',')})
          AND DATE(obs.obs_datetime) = (SELECT MAX(DATE(o.obs_datetime)) FROM obs o
                        WHERE o.concept_id IN(#{pregnant_concepts.join(',')}) AND voided = 0
                        AND o.person_id = obs.person_id AND o.obs_datetime <= '#{end_date.to_date.strftime('%Y-%m-%d 23:59:59')}')
          GROUP BY obs.person_id"
        )

       female_maternal_status = results.blank? ? 'FNP' : 'FP'
       

       if female_maternal_status == 'FNP'
          
        breastfeeding_concepts = []
        breastfeeding_concepts <<  ConceptName.find_by_name('Breast feeding?').concept_id
        breastfeeding_concepts <<  ConceptName.find_by_name('Breast feeding').concept_id
        breastfeeding_concepts <<  ConceptName.find_by_name('Breastfeeding').concept_id

        results2 = ActiveRecord::Base.connection.select_all(
          "SELECT person_id  FROM obs obs
            INNER JOIN encounter enc ON enc.encounter_id = obs.encounter_id AND enc.voided = 0
          WHERE obs.person_id =#{patient_id}
          AND obs.obs_datetime <= '#{end_date.to_date.strftime('%Y-%m-%d 23:59:59')}'
          AND obs.concept_id IN(#{breastfeeding_concepts.join(',')}) AND obs.value_coded = 1065
          AND obs.voided = 0 AND enc.encounter_type IN(#{encounter_types.join(',')})
          AND DATE(obs.obs_datetime) = (SELECT MAX(DATE(o.obs_datetime)) FROM obs o
                        WHERE o.concept_id IN(#{breastfeeding_concepts.join(',')}) AND voided = 0
                        AND o.person_id = obs.person_id AND o.obs_datetime <='#{end_date.to_date.strftime('%Y-%m-%d 23:59:59')}')
          GROUP BY obs.person_id;"
        )
      
         female_maternal_status = results2.blank? ? 'FNP' : 'FBf'
       end


       ActiveRecord::Base.connection.execute <<EOF
        UPDATE temp_disaggregated SET maternal_status =  '#{female_maternal_status}', 
           age_group = '#{age_group}' WHERE patient_id = #{patient_id};
EOF


      end

      def big_insert(data, age_group)
        
        (data || []).each do |r|
          ActiveRecord::Base.connection.execute <<EOF
            INSERT INTO temp_disaggregated (patient_id, age_group)
            VALUES(#{r['patient_id']}, '#{age_group}');
EOF

        end

      end
      
    end
  end

end

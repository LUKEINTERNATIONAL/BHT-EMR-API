module ARTService
  module Reports
    module Pepfar

      class TxMl
        def initialize(start_date:, end_date:)
          @start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
          @end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
        end

        def data
          return tx_ml
        end


        private

        def tx_ml
          data  = {}
          patients  = get_potential_tx_ml_clients
          patient_ids  = []

          (patients || []).each do |pat|
            patient_ids << pat['patient_id']
          end

          return [] if patient_ids.blank?

          filtered_patients = ActiveRecord::Base.connection.select_all <<EOF
          SELECT
            p.person_id patient_id, birthdate, gender,
            pepfar_patient_outcome(p.person_id, date('#{@end_date}')) outcome,
            cohort_disaggregated_age_group(p.birthdate, DATE('#{@end_date}')) age_group
          FROM person p WHERE p.person_id IN(#{patient_ids.join(",")}) GROUP BY p.person_id;
EOF

          (filtered_patients || []).each do |pat|
            outcome = pat['outcome']
            next if outcome == 'On antiretrovirals'

            patient_id = pat['patient_id'].to_i
            gender = pat['gender'].first.upcase rescue 'Unknown'
            age_group = pat['age_group']

            if data[age_group].blank?
              data[age_group]= {}
              data[age_group][gender] = [0, 0, 0, 0, 0]
            elsif data[age_group][gender].blank?
              data[age_group][gender] = [0, 0, 0, 0, 0]
            end

            case outcome
              when 'Defaulted'
                data[age_group][gender][0] +=  1
              when 'Patient died'
                data[age_group][gender][1] +=  1
              when 'Stopped'
                data[age_group][gender][2] +=  1
              when 'Patient transferred out'
                data[age_group][gender][3] +=  1
              else
                data[age_group][gender][4] +=  1

            end
          end

          return data
        end

        def get_potential_tx_ml_clients
          return ActiveRecord::Base.connection.select_all <<EOF
          select
            `p`.`patient_id` AS `patient_id`, pe.birthdate, pe.gender,
             cast(patient_date_enrolled(`p`.`patient_id`) as date) AS `date_enrolled`
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
                and (DATE(`s`.`start_date`) <= '#{@start_date.to_date.strftime("%Y-%m-%d 23:59:59")}')
                and pepfar_patient_outcome(p.patient_id, DATE('#{@start_date}')) = 'On antiretrovirals'
          group by `p`.`patient_id`
          HAVING date_enrolled IS NOT NULL;
EOF

        end


      end




    end
  end
end

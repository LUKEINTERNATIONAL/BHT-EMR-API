class ProgramAppointmentService
  extend ModelUtils

  def self.booked_appointments(program_id, date)
    clients = ActiveRecord::Base.connection.select_all("SELECT
    i.identifier, p.birthdate, p.gender, n.given_name,
    n.family_name, obs.person_id, p.birthdate_estimated
    FROM obs
    INNER JOIN encounter e ON e.encounter_id = obs.encounter_id
    AND e.voided = 0 AND obs.voided = 0 AND e.program_id = #{program_id}
    AND e.encounter_type = #{encounter_type('APPOINTMENT').id}
    RIGHT JOIN person p ON p.person_id = e.patient_id AND p.voided = 0
    RIGHT JOIN person_address a ON a.person_id = e.patient_id AND a.voided = 0
    RIGHT JOIN person_name n ON n.person_id = e.patient_id AND n.voided = 0
    RIGHT JOIN patient_identifier i ON i.patient_id = e.patient_id AND i.voided = 0
    AND i.identifier_type IN(2,3)
    WHERE obs.concept_id = #{concept('Appointment date').concept_id}
    AND value_datetime BETWEEN '#{date.strftime('%Y-%m-%d 00:00:00')}'
    AND '#{date.strftime('%Y-%m-%d 23:59:59')}'
    GROUP BY i.identifier, p.birthdate, p.gender,
    n.given_name, n.family_name,
    obs.person_id, p.birthdate_estimated;")

    clients_formatted = []
    already_counted = []

    (clients || []).each do |c|
      next if already_counted.include? c['person_id']
      already_counted << c['person_id']

      clients_formatted << {
        given_name: c['given_name'], family_name: c['family_name'],
        birthdate: c['birthdate'], gender: c['gender'], person_id: c['person_id'],
        npid: c['identifier'], birthdate_estimated: c['birthdate_estimated']
      }
    end

    return clients_formatted
  end
end
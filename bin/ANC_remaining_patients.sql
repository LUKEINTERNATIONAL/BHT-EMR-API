create table ANC_patients_merged_into_main_dbs as 
select ANC_patient_id from ANC_patient_details
union
select patient_id from ANC_only_patients_details;

select pi.patient_id, pn.family_name, pn.given_name, pi.identifier, p.gender, p.birthdate from patient_identifier pi
 inner join person_name pn on pn.person_id = pi.patient_id
 inner join person p on p.person_id = pi.patient_id
where pi.identifier_type = 3 and pi.voided = 0 and pi.patient_id not in (select ANC_patient_id from ANC_patients_merged_into_main_dbs);
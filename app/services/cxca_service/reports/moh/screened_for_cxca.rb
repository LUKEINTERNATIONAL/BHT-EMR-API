module CXCAService
  module Reports
		module Moh


			class ScreenedForCxca
				def initialize(start_date:, end_date:)
					@start_date = start_date.strftime('%Y-%m-%d 00:00:00')
					@end_date = end_date.strftime('%Y-%m-%d 23:59:59')
				end

				def data
					return screened
				end

				private

				def screened
					screening_method = concept 'CxCa screening method'
					obs = Observation.where("obs.concept_id = ? AND p.gender IN(?)
					AND obs_datetime BETWEEN ? AND ?", screening_method.concept_id,
					['F','Female'], @start_date, @end_date).\
					joins("INNER JOIN person p ON p.person_id = obs.person_id
					INNER JOIN concept_name m ON m.concept_id = obs.value_coded").\
					group("p.person_id, DATE(obs_datetime)").select("p.birthdate, m.concept_id, m.name, obs.obs_datetime,
					TIMESTAMPDIFF(year, p.birthdate, DATE(obs_datetime)) age")

					formated_obs = []
					(obs || []).each do |ob|
						formated_obs << {
							screened_method: ob.name,
							birthdate: ob.birthdate,
							obs_datetime: ob.obs_datetime.to_date,
							age_in_years: ob.age
						}
					end

					return formated_obs
				end

				def concept(name)
					ConceptName.find_by_name(name)
				end
			end

		end
	end
end
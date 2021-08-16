# frozen_string_literal: true

class Api::V1::VisitsController < ApplicationController
  def index
    filters = params.permit(%i[date_started visit_type program patient_id status])

    visits = service.find_visits(patient_id: filters[:patient_id],
                                 program_name: filters[:program],
                                 date_started: filters[:date_started],
                                 visit_type_name: filters[:visit_type],
                                 status: filters[:status])

    render json: visits
  end

  private

  def service
    VisitService
  end
end

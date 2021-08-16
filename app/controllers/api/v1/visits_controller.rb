# frozen_string_literal: true

class Api::V1::VisitsController < ApplicationController
  def create
    form = params.require(:visit).permit(%i[patient_id program_id date_started visit_type_id])
    visit = service.new_visit(patient_id: form[:patient_id],
                              program_id: form[:program_id],
                              date_started: form[:date_started]&.to_date,
                              visit_type_id: form[:visit_type_id])

    render json: visit, status: :created
  end

  def index
    filters = params.permit(%i[date_started visit_type program patient_id status])

    visits = service.find_visits(patient_id: filters[:patient_id],
                                 program_id: filters[:program_id],
                                 date_started: filters[:date_started],
                                 visit_type_id: filters[:visit_type_id],
                                 status: filters[:status])

    render json: visits
  end

  private

  def service
    VisitService
  end
end

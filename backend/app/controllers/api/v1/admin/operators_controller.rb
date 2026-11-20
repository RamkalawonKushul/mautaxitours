module Api
  module V1
    module Admin
      class OperatorsController < BaseController
        def index
          operators = Operator.order(active: :desc, name: :asc)
          if params[:q].present?
            term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
            operators = operators.where("name ILIKE :term OR contact_person ILIKE :term OR email ILIKE :term OR phone ILIKE :term", term: term)
          end
          render json: operators.map { |operator| serialize(operator) }
        end

        def create
          operator = Operator.new(operator_params)
          if operator.save
            render json: serialize(operator), status: :created
          else
            render json: { errors: operator.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          operator = Operator.find(params[:id])
          if operator.update(operator_params)
            render json: serialize(operator)
          else
            render json: { errors: operator.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          operator = Operator.find(params[:id])
          operator.update!(active: false)
          head :no_content
        end

        private

        def operator_params
          params.require(:operator).permit(
            :name, :contact_person, :email, :phone, :whatsapp, :address,
            :payment_terms, :notes, :active,
            service_types: [], vehicle_categories: []
          )
        end

        def serialize(operator)
          operator.as_json(only: %i[id name contact_person email phone whatsapp address service_types vehicle_categories payment_terms notes active created_at updated_at])
        end
      end
    end
  end
end

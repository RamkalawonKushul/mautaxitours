module Api
  module V1
    module Admin
      class OperatorAssignmentsController < BaseController
        def index
          assignments = OperatorAssignment.includes(:operator, :booking).order(created_at: :desc).limit(500)
          render json: assignments.map { |assignment| serialize(assignment) }
        end

        def create
          booking = Booking.find(params.require(:operator_assignment).fetch(:booking_id))
          operator = Operator.active.find(params.require(:operator_assignment).fetch(:operator_id))
          attributes = assignment_params
          currency = (attributes[:currency].presence || booking.currency).to_s.upcase
          unless currency == booking.currency
            return render json: { error: "Operator cost currency must match the booking currency. Currency conversion is not enabled." }, status: :unprocessable_entity
          end

          assignment = booking.operator_assignments.build(
            attributes.except(:booking_id, :operator_id).merge(operator: operator, currency: currency)
          )
          if assignment.save
            render json: serialize(assignment), status: :created
          else
            render json: { errors: assignment.errors.full_messages }, status: :unprocessable_entity
          end
        rescue ActionController::ParameterMissing, KeyError
          render json: { error: "Choose a booking and an active operator." }, status: :unprocessable_entity
        end

        def update
          assignment = OperatorAssignment.find(params[:id])
          attributes = assignment_params.except(:booking_id, :operator_id)
          currency = (attributes[:currency].presence || assignment.currency).to_s.upcase
          unless currency == assignment.booking.currency
            return render json: { error: "Operator cost currency must match the booking currency. Currency conversion is not enabled." }, status: :unprocessable_entity
          end

          if assignment.update(attributes.merge(currency: currency))
            render json: serialize(assignment)
          else
            render json: { errors: assignment.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def assignment_params
          params.require(:operator_assignment).permit(
            :booking_id, :operator_id, :status, :operator_cost_cents, :currency,
            :operator_paid_cents, :operator_confirmation_reference, :notes
          )
        end

        def serialize(assignment)
          booking = assignment.booking
          active_costs = booking.operator_assignments.where.not(status: %w[declined cancelled reassigned]).sum(:operator_cost_cents)
          {
            id: assignment.id,
            status: assignment.status,
            operator_cost_cents: assignment.operator_cost_cents,
            operator_paid_cents: assignment.operator_paid_cents,
            payment_status: assignment.payment_status,
            currency: assignment.currency,
            operator_confirmation_reference: assignment.operator_confirmation_reference,
            notes: assignment.notes,
            sent_at: assignment.sent_at,
            accepted_at: assignment.accepted_at,
            completed_at: assignment.completed_at,
            created_at: assignment.created_at,
            operator: assignment.operator.as_json(only: %i[id name contact_person email phone whatsapp active]),
            booking: {
              id: booking.id,
              reference: booking.reference,
              customer_name: booking.customer_name,
              customer_email: booking.customer_email,
              customer_phone: booking.customer_phone,
              travel_date: booking.travel_date,
              pickup_details: booking.pickup_details,
              special_requests: booking.special_requests,
              total_cents: booking.total_cents,
              currency: booking.currency,
              items: booking.booking_items.includes(:tour).map do |item|
                {
                  tour: item.tour.name,
                  travel_date: item.travel_date,
                  adults: item.adults,
                  children: item.children,
                  babies: item.babies,
                  vehicle: item.vehicle_name
                }
              end
            },
            booking_operator_cost_cents: active_costs,
            estimated_margin_cents: booking.total_cents.to_i - active_costs
          }
        end
      end
    end
  end
end

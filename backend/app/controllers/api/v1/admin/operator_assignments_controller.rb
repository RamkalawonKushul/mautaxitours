module Api
  module V1
    module Admin
      class OperatorAssignmentsController < BaseController
        def index
          assignments = OperatorAssignment.includes(:operator, :booking, :transport_enquiry).order(created_at: :desc).limit(500)
          render json: assignments.map { |assignment| serialize(assignment) }
        end

        def create
          attributes = assignment_params
          has_booking = attributes[:booking_id].present?
          has_transfer = attributes[:transport_enquiry_id].present?
          unless has_booking ^ has_transfer
            return render json: { error: "Choose exactly one tour booking or transfer enquiry." }, status: :unprocessable_entity
          end

          booking = Booking.find(attributes[:booking_id]) if has_booking
          enquiry = TransportEnquiry.find(attributes[:transport_enquiry_id]) if has_transfer
          operator = Operator.active.find(attributes[:operator_id])
          currency = (attributes[:currency].presence || booking&.currency || "MUR").to_s.upcase
          if booking && currency != booking.currency
            return render json: { error: "Operator cost currency must match the booking currency. Currency conversion is not enabled." }, status: :unprocessable_entity
          end

          customer_price = booking ? booking.total_cents : attributes[:customer_price_cents]
          if enquiry && customer_price.to_i <= 0
            return render json: { error: "Enter the customer selling price for this transfer before assigning an operator." }, status: :unprocessable_entity
          end

          assignment = nil
          OperatorAssignment.transaction do
            enquiry.operator_assignments.where.not(status: %w[declined cancelled reassigned]).update_all(status: "reassigned", updated_at: Time.current) if enquiry
            assignment = OperatorAssignment.new(
              attributes.except(:booking_id, :transport_enquiry_id, :operator_id, :customer_price_cents)
                         .merge(booking: booking, transport_enquiry: enquiry, operator: operator, currency: currency, customer_price_cents: customer_price)
            )
            assignment.save!
          end
          render json: serialize(assignment), status: :created
        rescue ActionController::ParameterMissing, KeyError
          render json: { error: "Choose a customer request and an active operator." }, status: :unprocessable_entity
        rescue ActiveRecord::RecordInvalid => error
          render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
        end

        def update
          assignment = OperatorAssignment.find(params[:id])
          attributes = assignment_params.except(:booking_id, :transport_enquiry_id, :operator_id)
          expected_currency = assignment.booking&.currency
          currency = (attributes[:currency].presence || assignment.currency).to_s.upcase
          if expected_currency.present? && currency != expected_currency
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
            :booking_id, :transport_enquiry_id, :operator_id, :status,
            :operator_cost_cents, :customer_price_cents, :currency,
            :operator_paid_cents, :operator_confirmation_reference, :notes
          )
        end

        def serialize(assignment)
          booking = assignment.booking
          enquiry = assignment.transport_enquiry
          if booking
            request_data = {
              id: booking.id, reference: booking.reference, customer_name: booking.customer_name,
              customer_email: booking.customer_email, customer_phone: booking.customer_phone,
              travel_date: booking.travel_date, pickup_details: booking.pickup_details,
              special_requests: booking.special_requests, total_cents: booking.total_cents,
              currency: booking.currency,
              items: booking.booking_items.includes(:tour).map do |item|
                { tour: item.tour.name, travel_date: item.travel_date, adults: item.adults, children: item.children, babies: item.babies, vehicle: item.vehicle_name }
              end
            }
            active_costs = booking.operator_assignments.where.not(status: %w[declined cancelled reassigned]).sum(:operator_cost_cents)
            record_type = "booking"
          else
            request_data = {
              id: enquiry.id, reference: enquiry.reference, customer_name: enquiry.contact_name,
              customer_email: enquiry.contact_email, customer_phone: enquiry.contact_phone,
              travel_date: enquiry.travel_date,
              pickup_details: "#{enquiry.pickup_location} → #{enquiry.destination} at #{enquiry.pickup_time}",
              special_requests: [enquiry.notes, ("Flight: #{enquiry.flight_number}" if enquiry.flight_number.present?), ("Luggage: #{enquiry.luggage}" if enquiry.luggage.present?)].compact.join(" | "),
              total_cents: assignment.customer_price_cents, currency: assignment.currency,
              items: [{ tour: "Private transfer", travel_date: enquiry.travel_date, adults: enquiry.passengers, children: 0, babies: 0, vehicle: enquiry.vehicle_preference }]
            }
            active_costs = enquiry.operator_assignments.where.not(status: %w[declined cancelled reassigned]).sum(:operator_cost_cents)
            record_type = "transfer"
          end

          {
            id: assignment.id, record_type: record_type, booking_id: booking&.id, transport_enquiry_id: enquiry&.id,
            status: assignment.status, operator_cost_cents: assignment.operator_cost_cents,
            customer_price_cents: assignment.customer_price_cents || booking&.total_cents,
            operator_paid_cents: assignment.operator_paid_cents, payment_status: assignment.payment_status,
            currency: assignment.currency, operator_confirmation_reference: assignment.operator_confirmation_reference,
            notes: assignment.notes, sent_at: assignment.sent_at, accepted_at: assignment.accepted_at,
            completed_at: assignment.completed_at, created_at: assignment.created_at,
            operator: assignment.operator.as_json(only: %i[id name contact_person email phone whatsapp active]),
            booking: request_data, booking_operator_cost_cents: active_costs,
            estimated_margin_cents: request_data[:total_cents].to_i - active_costs
          }
        end
      end
    end
  end
end

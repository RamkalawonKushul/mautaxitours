class SupportTransferEnquiryOperatorAssignments < ActiveRecord::Migration[8.0]
  def change
    change_column_null :operator_assignments, :booking_id, true
    add_reference :operator_assignments, :transport_enquiry, null: true, foreign_key: true
    add_column :operator_assignments, :customer_price_cents, :integer
  end
end

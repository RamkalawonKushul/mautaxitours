class ExpandBookingItemsForPassengerAndVehicleDetails < ActiveRecord::Migration[8.0]
  def change
    add_column :booking_items, :travel_date, :date
    add_column :booking_items, :adults, :integer, null: false, default: 1
    add_column :booking_items, :children, :integer, null: false, default: 0
    add_column :booking_items, :babies, :integer, null: false, default: 0
    add_reference :booking_items, :vehicle_option, foreign_key: true
    add_column :booking_items, :vehicle_name, :string
    add_column :booking_items, :transport_cents, :integer, null: false, default: 0
    add_column :booking_items, :vehicle_upgrade_cents, :integer, null: false, default: 0
    add_column :booking_items, :activity_cents, :integer, null: false, default: 0
    add_column :booking_items, :quoted_separately, :boolean, null: false, default: false
  end
end

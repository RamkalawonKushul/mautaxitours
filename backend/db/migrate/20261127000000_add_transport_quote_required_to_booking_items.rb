class AddTransportQuoteRequiredToBookingItems < ActiveRecord::Migration[8.0]
  def change
    add_column :booking_items, :transport_quote_required, :boolean, null: false, default: false
  end
end

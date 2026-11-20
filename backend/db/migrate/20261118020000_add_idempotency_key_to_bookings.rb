class AddIdempotencyKeyToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :idempotency_key, :string
    add_index :bookings, :idempotency_key, unique: true, where: "idempotency_key IS NOT NULL"
  end
end

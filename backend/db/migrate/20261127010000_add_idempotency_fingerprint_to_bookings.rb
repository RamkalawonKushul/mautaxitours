class AddIdempotencyFingerprintToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :idempotency_fingerprint, :string
  end
end

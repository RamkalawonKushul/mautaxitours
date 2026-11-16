class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :booking, null: false, foreign_key: true
      t.string :provider, null: false, default: "sbm"
      t.string :status, null: false, default: "initiated"
      t.string :currency, null: false
      t.integer :amount_cents, null: false
      t.integer :base_amount_mur_cents, null: false
      t.decimal :fx_rate_to_mur, precision: 20, scale: 10, null: false
      t.datetime :fx_quoted_at, null: false
      t.string :idempotency_key, null: false
      t.string :provider_transaction_id
      t.string :provider_payment_reference
      t.string :checkout_url
      t.datetime :expires_at
      t.datetime :paid_at
      t.string :failure_code
      t.jsonb :provider_metadata, null: false, default: {}
      t.timestamps
    end

    add_index :payments, :idempotency_key, unique: true
    add_index :payments, :provider_transaction_id, unique: true, where: "provider_transaction_id IS NOT NULL"
    add_index :payments, :provider_payment_reference, unique: true, where: "provider_payment_reference IS NOT NULL"
    add_index :payments, [:booking_id, :status]
  end
end

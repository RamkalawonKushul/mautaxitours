class CreateOperatorsAndOperatorAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :operators do |t|
      t.string :name, null: false
      t.string :contact_person
      t.string :email
      t.string :phone
      t.string :whatsapp
      t.text :address
      t.jsonb :service_types, null: false, default: []
      t.jsonb :vehicle_categories, null: false, default: []
      t.string :payment_terms
      t.text :notes
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :operators, :name
    add_index :operators, :active

    create_table :operator_assignments do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :operator, null: false, foreign_key: true
      t.string :status, null: false, default: "assigned"
      t.integer :operator_cost_cents, null: false, default: 0
      t.string :currency, null: false, default: "EUR"
      t.integer :operator_paid_cents, null: false, default: 0
      t.string :payment_status, null: false, default: "unpaid"
      t.string :operator_confirmation_reference
      t.datetime :sent_at
      t.datetime :accepted_at
      t.datetime :completed_at
      t.text :notes
      t.timestamps
    end
    add_index :operator_assignments, :status
    add_index :operator_assignments, :payment_status
    add_index :operator_assignments, [:booking_id, :created_at]
  end
end

class CreateAdminUsersAndVehicleOptions < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :admin_users, :email, unique: true

    create_table :vehicle_options do |t|
      t.string :name, null: false
      t.integer :capacity, null: false
      t.integer :upgrade_cents, null: false, default: 0
      t.string :currency, null: false, default: "EUR"
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :vehicle_options, :name, unique: true

    add_column :tours, :area, :string
    add_column :tours, :category_key, :string
    add_column :tours, :adult_price_cents, :integer
    add_column :tours, :child_price_cents, :integer
    add_column :tours, :baby_price_label, :string
    add_column :tours, :included_items, :jsonb, null: false, default: []
    add_column :tours, :excluded_items, :jsonb, null: false, default: []
    add_column :tours, :itinerary, :jsonb, null: false, default: []
  end
end

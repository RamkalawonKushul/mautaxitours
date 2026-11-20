class CreateBookingPlatformTables < ActiveRecord::Migration[8.0]
  def change
    create_table :tour_categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.timestamps
    end
    add_index :tour_categories, :name, unique: true
    add_index :tour_categories, :slug, unique: true

    create_table :tours do |t|
      t.references :tour_category, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :summary
      t.text :description
      t.string :image_url
      t.integer :duration_minutes
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: "MUR"
      t.boolean :published, null: false, default: false
      t.timestamps
    end
    add_index :tours, :slug, unique: true
    add_index :tours, :published

    create_table :bookings do |t|
      t.string :reference, null: false
      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.string :customer_phone
      t.date :travel_date, null: false
      t.text :pickup_details
      t.text :special_requests
      t.integer :total_cents, null: false, default: 0
      t.string :currency, null: false, default: "MUR"
      t.string :status, null: false, default: "pending"
      t.string :payment_status, null: false, default: "unpaid"
      t.string :payment_provider
      t.string :payment_reference
      t.timestamps
    end
    add_index :bookings, :reference, unique: true
    add_index :bookings, :travel_date
    add_index :bookings, :status

    create_table :booking_items do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :tour, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :unit_price_cents, null: false
      t.integer :line_total_cents, null: false
      t.timestamps
    end
  end
end

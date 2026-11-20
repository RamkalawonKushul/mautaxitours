class CreateTransportEnquiries < ActiveRecord::Migration[8.0]
  def change
    create_table :transport_enquiries do |t|
      t.string :reference, null: false
      t.string :pickup_location, null: false
      t.string :destination, null: false
      t.date :travel_date, null: false
      t.string :pickup_time, null: false
      t.integer :passengers, null: false
      t.string :vehicle_preference
      t.string :flight_number
      t.string :luggage
      t.text :notes
      t.string :contact_name
      t.string :contact_phone
      t.string :contact_email
      t.string :status, null: false, default: "new"
      t.timestamps
    end

    add_index :transport_enquiries, :reference, unique: true
    add_index :transport_enquiries, :travel_date
    add_index :transport_enquiries, :status
  end
end

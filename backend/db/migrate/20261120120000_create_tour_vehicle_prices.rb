class CreateTourVehiclePrices < ActiveRecord::Migration[8.0]
  def change
    create_table :tour_vehicle_prices do |t|
      t.references :tour, null: false, foreign_key: true
      t.references :vehicle_option, null: false, foreign_key: true
      t.integer :price_cents, null: false
      t.string :currency, null: false, default: "MUR"
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :tour_vehicle_prices, [:tour_id, :vehicle_option_id], unique: true, name: "index_tour_vehicle_prices_on_tour_and_vehicle"
  end
end

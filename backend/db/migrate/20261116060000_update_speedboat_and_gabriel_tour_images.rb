class UpdateSpeedboatAndGabrielTourImages < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE tours
      SET image_url = #{connection.quote("https://cdn.getyourguide.com/img/tour/5e2567bd79156.jpeg/140.jpg")}
      WHERE slug = 'speedileauxcerf-details'
    SQL
    execute <<~SQL
      UPDATE tours
      SET image_url = #{connection.quote("https://travelhub-mu.com/wp-content/uploads/2019/07/3.jpg")}
      WHERE slug = 'cataileauxgabriel-details'
    SQL
  end

  def down
    # The previous remote image URLs are intentionally not restored.
  end
end

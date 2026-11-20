class AddGalleryImageUrlsToTours < ActiveRecord::Migration[8.0]
  def change
    add_column :tours, :gallery_image_urls, :jsonb, null: false, default: []
  end
end

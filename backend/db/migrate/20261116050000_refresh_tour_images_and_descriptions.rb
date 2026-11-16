class RefreshTourImagesAndDescriptions < ActiveRecord::Migration[7.1]
  CONTENT = {
  "cataileauxcerf-details": {
    "summary": "Cruise to Île aux Cerfs with snorkelling, a BBQ lunch, drinks and a Grand River South East waterfall stop.",
    "description": "Sail from Pointe Jérôme along Mauritius’s beautiful east coast to Île aux Cerfs. Enjoy time on the island, a snorkelling stop, BBQ lunch and drinks, with a visit to the Grand River South East waterfall.",
    "image_url": "https://ileauxcerfscatamaran.com/images/home-ile-mauritius.jpg"
  },
  "cataileauxbenitier-details": {
    "summary": "Discover the west coast by catamaran, with dolphin watching, Crystal Rock, snorkelling and a beach stop at Île aux Bénitiers.",
    "description": "Set off from Black River for a west-coast catamaran cruise. Look out for dolphins near Tamarin, stop at Crystal Rock and relax on Île aux Bénitiers, with a BBQ lunch and drinks on board.",
    "image_url": "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1b/6d/ef/6e/caption.jpg?w=1200&h=-1&s=1"
  },
  "cataileauxgabriel-details": {
    "summary": "Spend the day sailing to Île aux Gabriel, known for its white-sand beaches, clear lagoon and excellent snorkelling.",
    "description": "Depart from Grand Baie for a full-day catamaran cruise to Île aux Gabriel in the northern lagoon. Enjoy the island’s white sands, clear water, swimming and snorkelling, with time to unwind by the sea.",
    "image_url": "https://www.islandcovemu.com/wp-content/uploads/2019/12/Tour-Image-Sea-North-Coast-Catamaran-1920x674-1.jpg"
  },
  "speedileauxcerf-details": {
    "summary": "Ride by speedboat to Île aux Cerfs, with a lagoon swim, waterfall visit and BBQ lunch.",
    "description": "Depart from the east coast for an exciting speedboat ride to Île aux Cerfs. Enjoy the island’s beaches, a lagoon or snorkelling stop when conditions allow, a Grand River South East waterfall visit and BBQ lunch.",
    "image_url": "https://dynamic-media-cdn.tacdn.com/media/photo-o/2e/fd/f0/88/caption.jpg?w=800&h=600&s=1"
  },
  "swimwithdolphine": {
    "summary": "Head out from Tamarin Bay for a guided dolphin-watching and open-sea experience.",
    "description": "Join a morning boat trip from Tamarin Bay to look for dolphins in their natural environment. The crew will brief guests before entering the water; sightings and swimming opportunities depend on sea conditions and responsible wildlife practices.",
    "image_url": "https://mauritiusexplored.com/wp-content/uploads/2019/05/Dolphin-swim-vitamin-sea.jpg"
  },
  "thechamarel": {
    "summary": "Explore Grand Bassin, Chamarel’s Seven Coloured Earth, waterfalls, rum heritage and scenic viewpoints.",
    "description": "Discover Mauritius’s south-west and central highlands on a private day tour. Visit Grand Bassin, Alexandra Falls, Black River Gorges, the Seven Coloured Earth, Chamarel Waterfall and the rum distillery, with scenic views along the way.",
    "image_url": "https://chamarel7colouredearth.com/media/dr0lkgpw/colorful-dunes-mask.jpg"
  },
  "casela": {
    "summary": "Visit Casela Nature Parks for wildlife encounters, safari experiences and outdoor adventures.",
    "description": "Spend time at Casela Nature Parks near Cascavelle, where you can explore wildlife areas and choose from safari and adventure activities. Park admission and optional experiences are purchased separately.",
    "image_url": "https://mauritiusdiscoverytours.com/wp-content/uploads/2019/07/Young-couple-feeding-giraffe-at-Casela-scaled.jpg"
  },
  "northtour": {
    "summary": "Discover the north’s heritage, from the Sugar Museum and Château de Labourdonnais to Cap Malheureux’s red-roof church.",
    "description": "Explore northern Mauritius on a private sightseeing tour. Highlights include L’Aventure du Sucre, Château de Labourdonnais, Grand Baie and the iconic red-roof church at Cap Malheureux, with time for coastal stops.",
    "image_url": "https://images.pexels.com/photos/34732391/pexels-photo-34732391.jpeg"
  },
  "southeast": {
    "summary": "Explore Blue Bay, Mahébourg’s waterfront and museums, the Manioc Biscuit Factory and historic sites.",
    "description": "Travel through Mauritius’s south-east to discover its coastal scenery and history. Visit Blue Bay, Mahébourg, the Manioc Biscuit Factory and heritage sites connected with the island’s early settlement.",
    "image_url": "https://mauritiusattractions.com/slir/w640-c2x1/content/images/gallery/205/the-blue-bay-beach-mauritius-maurice%20%281%29.jpg"
  },
  "southwest": {
    "summary": "See Le Morne, the Macondé viewpoint, coastal scenery and local attractions on a private south-west tour.",
    "description": "Discover the dramatic landscapes of south-west Mauritius, beginning at Le Morne and continuing along the scenic coastal road. Stop at the Macondé viewpoint and selected local attractions, with a flexible private-vehicle itinerary.",
    "image_url": "https://www.thediscoveriesof.com/wp-content/uploads/2022/12/Le-Morne-Brabant-mountain-and-underwater-waterfall-Mauritius-island-shutterstock_762828655.jpg.webp"
  },
  "teawildlife": {
    "summary": "Taste locally grown tea at Bois Chéri and explore heritage estates, wildlife and the south coast.",
    "description": "Discover the island’s tea heritage at Bois Chéri, with time for the plantation, factory and tasting. Continue through the south to selected heritage estates and La Vanille Nature Park, with coastal scenery at Gris Gris.",
    "image_url": "https://wpktirmzveoovxjqbqpq.supabase.co/storage/v1/render/image/public/images/bois-ch-ri-tea-factory-in-mauritius.webp?format=origin&quality=75&width=1200"
  },
  "portlouiscitytours": {
    "summary": "Explore Port Louis, including Caudan Waterfront, Chinatown, the central market and historic Fort Adelaide.",
    "description": "Discover the capital on a private city tour. Visit Marie Reine de la Paix, Caudan Waterfront, Chinatown and the central market, then enjoy panoramic views from Fort Adelaide; museum and oceanarium visits can be arranged separately.",
    "image_url": "https://upload.wikimedia.org/wikipedia/commons/c/c0/Fort_Adelaide_Port_Louis_2019-09-27_2.jpg"
  }
}.freeze

  def up
    CONTENT.each do |slug, attributes|
      execute <<~SQL
        UPDATE tours
        SET summary = #{connection.quote(attributes.fetch("summary"))},
            description = #{connection.quote(attributes.fetch("description"))},
            image_url = #{connection.quote(attributes.fetch("image_url"))}
        WHERE slug = #{connection.quote(slug)}
      SQL
    end
  end

  def down
    # Content refresh is intentionally irreversible; admins can change content in the CMS.
  end
end

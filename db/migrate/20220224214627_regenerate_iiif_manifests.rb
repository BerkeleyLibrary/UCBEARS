# Ensure migration can run without error even if we delete/rename the models
class Item < ActiveRecord::Base; end unless defined?(Item)

class RegenerateIIIFManifests < ActiveRecord::Migration[6.1]
  def change
    Item.find_each do |item|
      next unless (iiif_manifest = item.iiif_manifest)
      next if iiif_manifest.manifest_path.exist?

      iiif_manifest.write_manifest!
      item.update_complete_flag!
    end
  end
end

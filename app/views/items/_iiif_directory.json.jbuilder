path = iiif_directory.path
json.directory(path.basename)
json.path(path)
json.exists(iiif_directory.exists?)
json.complete(iiif_directory.complete?)
json.has_page_images(iiif_directory.page_images?)
json.has_marc_record(iiif_directory.marc_record?)
json.has_manifest_template(iiif_directory.manifest_template?)

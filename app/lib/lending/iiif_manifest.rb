require 'berkeley_library/util/uris'

module Lending
  class IIIFManifest
    include BerkeleyLibrary::Logging
    include ErbManifest
    include JsonManifest
    include ManifestBuilder
    include ManifestUpdater

    attr_reader :title
    attr_reader :author
    attr_reader :dir_path
    attr_reader :record_id
    attr_reader :barcode

    def initialize(title:, author:, dir_path:)
      @title = title
      @author = author
      @dir_path = PathUtils.ensure_dirpath(dir_path)
      @record_id, @barcode = PathUtils.decompose_dirname(@dir_path)
    end

    def pages
      @pages ||= Page.all_from_directory(dir_path)
    end

    def dir_basename
      dir_path.basename.to_s
    end

    # rubocop:disable Naming/PredicateName
    def has_manifest?
      json_template? || erb_template?
    end
    # rubocop:enable Naming/PredicateName

    def to_json_manifest(manifest_uri, image_root_uri)
      image_dir_uri = BerkeleyLibrary::Util::URIs.append(image_root_uri, ERB::Util.url_encode(dir_basename))
      return render_json_template(manifest_uri, image_dir_uri) if manifest_path.file?
      return render_erb_template(manifest_uri, image_dir_uri) if erb_path.file?

      raise ArgumentError, "#{record_id}_#{barcode}: manifest not found in #{dir_path}"
    end

    def to_s
      @s ||= "#{self.class.name.split('::').last}@#{object_id}"
    end
  end
end

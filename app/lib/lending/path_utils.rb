require 'pathname'

module Lending
  module PathUtils
    DIRNAME_RAW_RE = %r{[^/_]+_[^/]+}
    DIRNAME_RE = /^(?<record_id>[^_]+)_(?<barcode>.+)$/
    MSG_BAD_DIRNAME = "Item directory '%s' should be in the form <record_id>_<barcode>".freeze
    SEGMENT_RE = /^([[:graph:]][[:print:]]*[[:graph:]]|[[:graph:]])$/
    MSG_INVALID_BARCODE = "Item barcode '%s' contains invalid characters".freeze
    MSG_INVALID_RECORD_ID = "Item record ID '%s' contains invalid characters".freeze

    def each_item_dir(parent)
      parent = ensure_dirpath(parent)
      return to_enum(:each_item_dir, parent) unless block_given?

      parent.children.each { |p| yield p if item_dir?(p) }
    end

    def all_item_dirs(parent)
      ensure_dirpath(parent).children.select { |c| c.directory? && stem(c).to_s =~ DIRNAME_RE }
    end

    def item_dir?(p)
      pathname = ensure_pathname(p)
      pathname.directory? && stem(pathname).to_s =~ DIRNAME_RE
    end

    def ensure_pathname(p)
      p.is_a?(Pathname) ? p : Pathname.new(p.to_s)
    end

    def ensure_pathnames(*paths)
      paths.map { |p| ensure_pathname(p) }
    end

    def ensure_filepath(f)
      raise ArgumentError, "Not a file path: #{f}" unless f && File.file?(f.to_s)

      ensure_pathname(f)
    end

    def ensure_dirpath(dir)
      raise ArgumentError, "Not a directory: #{dir.inspect}" unless dir && File.directory?(dir.to_s)

      ensure_pathname(dir)
    end

    def ensure_non_directory(f)
      ensure_pathname(f).tap do |pathname|
        return ensure_filepath(pathname) if pathname.exist?
      end
    end

    def stem(p)
      path = ensure_pathname(p)
      path.basename(path.extname).to_s
    end

    def image?(p)
      pathname = ensure_pathname(p)
      pathname.file? && image_ext?(pathname)
    end

    def image_ext?(p)
      tiff_ext?(p) || jpeg_ext?(p)
    end

    def images_in(dir)
      # TODO: unify this with the other extension-checking methods
      path = ensure_dirpath(dir)
      pattern = path.join('*.{tif,jpg,jpeg}').to_s
      Pathname.glob(pattern)
    end

    def xml_ext?(p)
      pathname = ensure_pathname(p)
      pathname.extname.downcase == '.xml'
    end

    def tiff_ext?(p)
      pathname = ensure_pathname(p)
      pathname.extname.downcase =~ /\.tiff?$/
    end

    def jpeg_ext?(p)
      pathname = ensure_pathname(p)
      pathname.extname.downcase =~ /\.jpe?g$/
    end

    def txt_path_from(img_path)
      img_path = ensure_pathname(img_path)
      img_path.parent.join("#{stem(img_path)}.txt")
    end

    def decompose_dirname(path)
      match_data = DIRNAME_RE.match(path.basename.to_s)
      raise ArgumentError, format(MSG_BAD_DIRNAME, path) unless match_data

      barcode = match_data[:barcode]
      raise ArgumentError, format(MSG_INVALID_BARCODE) unless barcode =~ SEGMENT_RE

      # TODO: do we care about check digits?
      record_id = match_data[:record_id].downcase
      raise ArgumentError, format(MSG_INVALID_RECORD_ID) unless barcode =~ SEGMENT_RE

      [record_id, barcode]
    end

    class << self
      include PathUtils
    end
  end
end

class IIIFDirectory

  # ------------------------------------------------------------
  # Constants

  # TODO: Use Rails i18n
  MSG_NO_IIIF_DIR = 'The item directory does not exist, or is not a directory'.freeze
  MSG_NO_PAGE_IMAGES = 'The item directory has no page images'.freeze
  MSG_NO_MANIFEST_TEMPLATE = 'The item directory does not have a IIIF manifest template'.freeze
  MSG_NO_MARC_XML = "The item directory does not contain a #{Lending::Processor::MARC_XML_NAME} file".freeze

  # ------------------------------------------------------------
  # Accessors

  attr_reader :path

  # ------------------------------------------------------------
  # Initializer

  def initialize(directory)
    raise ArgumentError, 'Directory cannot be nil' unless directory

    @path = lending_root_final.join(directory)
  end

  # ------------------------------------------------------------
  # Flags

  def complete?
    exists? && page_images? && marc_record? && manifest_template?
  end

  def reason_incomplete
    return if complete?
    return "#{MSG_NO_IIIF_DIR}: #{path}" unless exists?
    return MSG_NO_PAGE_IMAGES unless page_images?
    return MSG_NO_MARC_XML unless marc_record?
    return MSG_NO_MANIFEST_TEMPLATE unless manifest_template?
  end

  def exists?
    return @exists if instance_variable_defined?(:@exists)

    @exists = path.exist?
  end

  def page_images?
    return @has_page_images if instance_variable_defined?(:@has_page_images)

    @has_page_images = page_images.any?
  end

  def marc_record?
    return @has_marc_record if instance_variable_defined?(:@has_marc_record)

    @has_marc_record = marc_path.exist?
  end

  def manifest_template?
    return @has_manifest_template if instance_variable_defined?(:@has_manifest_template)

    @has_manifest_template = manifest_template_path.exist?
  end

  # ------------------------------------------------------------
  # Accessors

  def marc_path
    @marc_path ||= path.join(Lending::Processor::MARC_XML_NAME)
  end

  # TODO: should this be on IIIFManifest instead?
  def manifest_template_path
    @manifest_template_path ||= path.join(Lending::IIIFManifest::MANIFEST_TEMPLATE_NAME)
  end

  def page_images
    return [] unless exists?

    path.children.lazy.select { |e| Lending::Page.page_image?(e) }
  end

  def marc_metadata
    return @marc_metadata if instance_variable_defined?(:@marc_metadata)

    @marc_metadata = load_marc_metadata
  end

  def first_image_url_path
    raise(Errno::ENOENT, "No page images found in #{path}") unless (first_image_path = page_images.first)

    first_image_path.relative_path_from(lending_root_final)
  end

  # ------------------------------------------------------------
  # Misc. instance methods

  def new_manifest(title:, author:)
    Lending::IIIFManifest.new(title: title, author: author, dir_path: path)
  end

  def load_marc_metadata
    Lending::MarcMetadata.from_file(marc_path).tap do |md|
      Rails.logger.warn("No MARC metadata found in #{marc_path}") unless md
    end
  end

  # ------------------------------------------------------------
  # Object overrides

  def to_s
    path.to_s
  end

  def inspect
    "#<IIIFDirectory:#{self}>"
  end

  private

  def lending_root_final
    Lending.stage_root_path(:final).expand_path
  end

end

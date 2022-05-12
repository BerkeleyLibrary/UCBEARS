class IIIFDirectory

  # ------------------------------------------------------------
  # Constants

  # TODO: Use Rails i18n
  MSG_NO_IIIF_DIR = 'The item directory does not exist, or is not a directory'.freeze
  MSG_NO_PAGE_IMAGES = 'The item directory has no page images'.freeze
  MSG_NO_MANIFEST = 'The item directory does not have a IIIF manifest'.freeze
  MSG_NO_MARC_XML = "The item directory does not contain a #{Lending::Processor::MARC_XML_NAME} file".freeze

  # ------------------------------------------------------------
  # Constants

  CACHE_EXPIRY = 5.minutes

  # ------------------------------------------------------------
  # Accessors

  attr_reader :path, :stage_root_path, :directory

  # ------------------------------------------------------------
  # Initializer

  def initialize(directory, stage: :final)
    raise ArgumentError, 'Directory cannot be nil' unless directory

    @directory = directory
    @stage_root_path = Lending.stage_root_path(stage).expand_path
    @path = stage_root_path.join(directory)
  end

  # ------------------------------------------------------------
  # Class methods

  class << self
    def fetch(directory, stage: :final)
      stage_root_path = Lending.stage_root_path(stage).expand_path
      path = stage_root_path.join(directory)

      cache.fetch(path.to_s) { new(directory, stage: stage) }
    end

    private

    # @return [ActiveSupport::Cache::MemoryStore]
    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new(
        coder: ActiveSupport::Cache::NullCoder,
        expires_in: CACHE_EXPIRY
      )
    end

  end

  # ------------------------------------------------------------
  # Flags

  def complete?
    @complete ||= exists? && page_images? && marc_record? && manifest?
  end

  def reason_incomplete
    return if complete?
    return "#{MSG_NO_IIIF_DIR}: #{path}" unless exists?
    return MSG_NO_PAGE_IMAGES unless page_images?
    return MSG_NO_MARC_XML unless marc_record?
    return MSG_NO_MANIFEST unless manifest?
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

  def manifest?
    return @has_manifest if instance_variable_defined?(:@has_manifest)

    @has_manifest = manifest_path.exist? || manifest_template_path.exist?
  end

  # ------------------------------------------------------------
  # Accessors

  def mtime
    path&.mtime
  end

  def marc_path
    @marc_path ||= path.join(Lending::Processor::MARC_XML_NAME)
  end

  # TODO: should this be on IIIFManifest instead?
  def manifest_template_path
    @manifest_template_path ||= path.join(Lending::IIIFManifest::MANIFEST_TEMPLATE_NAME)
  end

  def manifest_path
    @manifest_path ||= path.join(Lending::IIIFManifest::MANIFEST_NAME)
  end

  def page_images
    return [] unless exists?

    Lending::PathUtils.images_in(path)
  end

  def marc_metadata
    return @marc_metadata if instance_variable_defined?(:@marc_metadata)

    @marc_metadata = load_marc_metadata
  end

  def first_image_url_path
    raise(Errno::ENOENT, err_no_page_images) unless (first_image_path = page_images.first)

    first_image_path.relative_path_from(stage_root_path).to_s
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

  delegate :to_s, to: :path

  def inspect
    "#<IIIFDirectory:#{self}>"
  end

  private

  def err_no_page_images
    I18n.t('activerecord.errors.models.image.directory.no_page_images', dir: path)
  end

end

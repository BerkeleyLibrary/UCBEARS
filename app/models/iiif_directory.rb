class IIIFDirectory

  # ------------------------------------------------------------
  # Accessors

  attr_reader :path

  # ------------------------------------------------------------
  # Initializer

  def initialize(directory)
    raise ArgumentError, 'Directory cannot be nil' unless directory

    iiif_dir_relative = Lending.stage_root_path(:final).join(directory)
    @path = iiif_dir_relative.expand_path
  end

  # ------------------------------------------------------------
  # Flags

  def complete?
    exists? && page_images? && marc_record? && manifest_template?
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

  def manifest_template_path
    @manifest_template_path ||= path.join(Lending::IIIFManifest::MANIFEST_TEMPLATE_NAME)
  end

  def page_images
    return [] unless exists?

    path.children.lazy.select { |e| Lending::Page.page_image?(e) }
  end

  # ------------------------------------------------------------
  # Object overrides

  def to_s
    path.to_s
  end

  def inspect
    "#<IIIFDirectory:#{self}>"
  end

end

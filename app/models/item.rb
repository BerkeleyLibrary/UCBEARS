require 'berkeley_library/util/uris'

# rubocop:disable Metrics/ClassLength
class Item < ActiveRecord::Base

  # ------------------------------------------------------------
  # Relations

  has_many :loans, dependent: :destroy

  # ------------------------------------------------------------
  # Validations

  validates :directory, presence: true
  validates_uniqueness_of :directory
  validates :title, presence: true
  validates :copies, numericality: { greater_than_or_equal_to: 0 }
  validate :correct_directory_format
  validate :active_items_have_copies
  validate :active_items_are_complete

  # ------------------------------------------------------------
  # Constants

  DEBUG_ATTRIBUTES = %i[
    id
    directory
    status
    iiif_dir
    iiif_dir_exists?
    has_page_images?
    marc_path
    has_marc_record?
    manifest_template_path
    has_manifest_template?
    complete?
    active?
    copies
    copies_available
    available?
  ].freeze

  LOAN_DURATION_SECONDS = 2 * 3600 # TODO: make this configurable

  # TODO: Use Rails i18n
  MSG_CHECKED_OUT = 'You have already checked out this item.'.freeze
  MSG_UNAVAILABLE = 'There are no available copies of this item.'.freeze
  MSG_INCOMPLETE = 'This item has not yet been processed for viewing.'.freeze
  MSG_NOT_CHECKED_OUT = 'This item is not checked out.'.freeze
  MSG_ZERO_COPIES = 'Items without copies cannot be made active.'.freeze
  MSG_INACTIVE = 'This item is not in active circulation.'.freeze
  MSG_INVALID_DIRECTORY = 'directory should be in the format <bibliographic record id>_<item barcode>.'.freeze

  # TODO: make these warnings rather than validation-fatal errors
  #       then we can stop littering save(validate: false) everywhere
  MSG_NO_IIIF_DIR = 'The item directory does not exist, or is not a directory'.freeze
  MSG_NO_PAGE_IMAGES = 'The item directory has no page images'.freeze
  MSG_NO_MANIFEST_TEMPLATE = 'The item directory does not have a IIIF manifest template'.freeze
  MSG_NO_MARC_XML = "The item directory does not contain a #{Lending::Processor::MARC_XML_NAME} file".freeze

  # TODO: make this configurable
  MAX_CHECKOUTS_PER_PATRON = 1
  MSG_CHECKOUT_LIMIT_REACHED = "You may only check out #{MAX_CHECKOUTS_PER_PATRON} item at a time.".freeze

  # ------------------------------------------------------------
  # Class methods

  class << self
    # TODO: smarter sorting
    # TODO: cache completeness status in DB

    def active
      Item.where(active: true).order(:title).lazy.select(&:complete?)
    end

    def inactive
      Item.where(active: false).order(:title).lazy.select(&:complete?)
    end

    def incomplete
      # TODO: get order working (requires abandoning find_each)
      Item.order(:title).find_each.lazy.reject(&:complete?)
    end

    def scan_for_new_items!
      Lending.each_final_dir.map do |dir_path|
        basename = dir_path.basename.to_s
        next if exists?(directory: basename)

        create_from(basename)
      end.compact
    end

    def create_from(directory)
      logger.info("Creating item for directory #{directory}")

      Item.new(directory: directory, copies: 0).tap do |item|
        unless item.marc_metadata
          logger.error("Unable to read MARC record from #{item.marc_path}")
          return nil
        end

        item.read_marc_metadata
        item.save(validate: false)
      end
    end
  end

  # ------------------------------------------------------------
  # ActiveRecord overrides

  def reload(options = nil)
    super

    @iiif_directory = nil
  end

  # ------------------------------------------------------------
  # Instance methods

  # @return [Loan] the created loan
  def check_out_to(patron_identifier)
    loan_date = Time.now.utc
    due_date = loan_date + LOAN_DURATION_SECONDS.seconds

    Loan.create(
      item_id: id,
      patron_identifier: patron_identifier, # TODO: rename to borrower_id
      loan_date: loan_date,
      due_date: due_date
    )
  end

  def check_out_to!(patron_identifier)
    check_out_to(patron_identifier).tap do |loan|
      raise ArgumentError, loan.errors.full_messages.join(' ').to_s unless loan.persisted?
    end
  end

  # TODO: find a better way to make sure we reflect the most current title & author in the manifest
  #       - stop storing title and author?
  #       - cache page image info & generate manifest on the fly?
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def to_json_manifest(manifest_uri)
    mf_json_src = iiif_manifest.to_json_manifest(manifest_uri, Lending::Config.iiif_base_uri)
    mf_json = JSON.parse(mf_json_src)

    mf_metadata = mf_json['metadata']
    mf_title, mf_author = %w[Title Author].map { |k| mf_metadata.find { |entry| entry['label'] == k } }
    title_changed = mf_json['label'] != title || mf_title['value'] != title
    author_changed = mf_author['value'] != author
    return mf_json_src unless title_changed || author_changed

    mf_title['value'] = title
    mf_author['value'] = author
    mf_json['label'] = title

    JSON.pretty_generate(mf_json)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def refresh_marc_metadata!
    read_marc_metadata
    save(validate: false) if changed?

    previous_changes
  end

  def read_marc_metadata
    return unless marc_metadata

    attrs = {
      author: marc_metadata.author,
      title: marc_metadata.title,
      publisher: marc_metadata.publisher,
      physical_desc: marc_metadata.physical_desc
    }.filter { |_, v| !v.blank? }
    assign_attributes(attrs)
  end

  # ------------------------------------------------------------
  # Synthetic accessors

  def debug_hash
    DEBUG_ATTRIBUTES.map do |attr|
      raw_value = send(attr)
      [attr, loggable_value_for(raw_value)]
    end.to_h
  end

  def complete?
    iiif_dir_exists? && has_page_images? && has_marc_record? && has_manifest_template?
  end

  def incomplete?
    !complete?
  end

  def available?
    active? && complete? && copies_available > 0
  end

  def inactive?
    !active?
  end

  def status
    return 'Incomplete' if incomplete?

    active? ? 'Active' : 'Inactive'
  end

  # TODO: move these to an ItemValidator class or something
  def reason_unavailable
    return if available?
    return Item::MSG_INACTIVE unless active?
    return Item::MSG_INCOMPLETE unless complete?
    return Item::MSG_UNAVAILABLE unless (due_date = next_due_date)

    date_str = due_date.to_s(:long)
    "#{Item::MSG_UNAVAILABLE} It will be returned on #{date_str}"
  end

  # TODO: move these to an ItemValidator class or something
  def reason_incomplete
    return if complete?
    return "#{MSG_NO_IIIF_DIR}: #{iiif_dir}" unless iiif_dir_exists?
    return MSG_NO_PAGE_IMAGES unless has_page_images?
    return MSG_NO_MARC_XML unless has_marc_record?
    return MSG_NO_MANIFEST_TEMPLATE unless has_manifest_template?
  end

  def copies_available
    total_copies = copies || 0 # TODO: make this non-nullable
    (total_copies - loans.active.count)
  end

  def due_dates
    active_loans.pluck(:due_date)
  end

  def next_due_date
    return unless (next_loan_due = active_loans.first)

    next_loan_due.due_date
  end

  def iiif_manifest
    return unless iiif_directory.exists?

    Lending::IIIFManifest.new(title: title, author: author, dir_path: iiif_directory.path)
  end

  def marc_metadata
    return @marc_metadata if instance_variable_defined?(:@marc_metadata)

    @marc_metadata = load_marc_metadata
  end

  def iiif_dir
    iiif_directory.path.to_s
  end

  def iiif_directory
    @iiif_directory ||= IIIFDirectory.new(directory)
  end

  def record_id
    ensure_record_id_and_barcode
    @record_id
  end

  def barcode
    ensure_record_id_and_barcode
    @barcode
  end

  def iiif_dir_exists?
    iiif_directory.exists?
  end

  # rubocop:disable Naming/PredicateName
  def has_page_images?
    iiif_directory.page_images?
  end
  # rubocop:enable Naming/PredicateName

  # ------------------------------------------------------------
  # Custom validators

  # TODO: move all of these to an ItemValidator class or something

  def correct_directory_format
    return if Lending::PathUtils::DIRNAME_RE =~ directory

    errors.add(:base, MSG_INVALID_DIRECTORY)
  end

  def active_items_have_copies
    return if inactive? || copies > 0

    errors.add(:base, MSG_ZERO_COPIES)
  end

  def active_items_are_complete
    return if inactive? || complete?

    errors.add(:base, reason_incomplete)
  end

  def active_loans
    loans.active.order(:due_date)
  end

  # rubocop:disable Naming/PredicateName
  def has_marc_record?
    iiif_directory.marc_record?
  end
  # rubocop:enable Naming/PredicateName

  # rubocop:disable Naming/PredicateName
  def has_manifest_template?
    iiif_directory.manifest_template?
  end
  # rubocop:enable Naming/PredicateName

  def marc_path
    iiif_directory.marc_path
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def loggable_value_for(raw_value)
    return raw_value.to_s if raw_value.is_a?(Pathname)

    raw_value
  end

  def manifest_template_path
    iiif_manifest&.erb_path
  end

  def load_marc_metadata
    Lending::MarcMetadata.from_file(marc_path).tap do |md|
      Rails.logger.warn("No MARC metadata found in #{marc_path}") unless md
    end
  end

  def ensure_record_id_and_barcode
    return if @record_id && @barcode

    @record_id, @barcode = directory.split('_')
  end
end
# rubocop:enable Metrics/ClassLength

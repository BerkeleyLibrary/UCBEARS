require 'lending'
require 'ucblit/util/uris'

# rubocop:disable Metrics/ClassLength
class LendingItem < ActiveRecord::Base

  # ------------------------------------------------------------
  # Relations

  has_many :lending_item_loans, dependent: :destroy

  # ------------------------------------------------------------
  # Callbacks

  after_update :return_loans_if_inactive

  # ------------------------------------------------------------
  # Validations

  validates :directory, presence: true
  validates_uniqueness_of :directory
  validates :title, presence: true
  validates :author, presence: true
  validates :copies, numericality: { greater_than_or_equal_to: 0 }
  validate :correct_directory_format
  validate :active_items_have_copies
  validate :active_items_are_complete

  # ------------------------------------------------------------
  # Constants

  LOAN_DURATION_SECONDS = 2 * 3600 # TODO: make this configurable

  # TODO: Use Rails i18n
  MSG_CHECKED_OUT = 'You have already checked out this item.'.freeze
  MSG_UNAVAILABLE = 'There are no available copies of this item.'.freeze
  MSG_INCOMPLETE = 'This item has not yet been processed for viewing.'.freeze
  MSG_NOT_CHECKED_OUT = 'This item is not checked out.'.freeze
  MSG_ZERO_COPIES = 'Items without copies cannot be made active.'.freeze
  MSG_INACTIVE = 'This item is not in active circulation.'.freeze
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
    def active
      LendingItem.where(active: true).lazy.select(&:complete?)
    end

    def inactive
      LendingItem.where(active: false).lazy.select(&:complete?)
    end

    def incomplete
      LendingItem.find_each.lazy.reject(&:complete?)
    end

    def scan_for_new_items!
      known_directories = LendingItem.pluck(:directory)

      item_dirs = Lending::PathUtils.each_item_dir(iiif_final_root).to_a

      item_dirs.filter_map do |item_dir|
        stem = Lending::PathUtils.stem(item_dir).to_s
        next if known_directories.include?(stem)

        create_from(stem)
      end
    end

    def create_from(directory)
      return unless (item_dir = Pathname.new(iiif_final_root).join(directory)).directory?
      return unless (marc_path = item_dir.join(Lending::Processor::MARC_XML_NAME)).exist?

      metadata = Lending::MarcMetadata.from_file(marc_path)
      item = LendingItem.create(directory: directory, title: metadata.title, author: metadata.author, copies: 0)
      return item if item.persisted?
    end

    # TODO: move this to a helper
    def iiif_final_root
      Rails.application.config.iiif_final_dir.tap do |dir|
        raise ArgumentError, 'iiif_final_dir not set' if dir.blank?
        raise ArgumentError, "iiif_final_dir #{dir} is not a directory" unless File.directory?(dir)
      end
    end

  end

  # ------------------------------------------------------------
  # Instance methods

  # @return [LendingItemLoan] the created loan
  def check_out_to(patron_identifier)
    loan_date = Time.now.utc
    due_date = loan_date + LOAN_DURATION_SECONDS.seconds

    LendingItemLoan.create(
      lending_item_id: id,
      patron_identifier: patron_identifier,
      loan_status: :active,
      loan_date: loan_date,
      due_date: due_date
    )
  end

  def check_out_to!(patron_identifier)
    check_out_to(patron_identifier).tap do |loan|
      raise ArgumentError, loan.errors.full_messages.join(' ').to_s unless loan.persisted?
    end
  end

  def to_json_manifest(manifest_uri)
    iiif_manifest.to_json(manifest_uri, image_server_base_uri)
  end

  # ------------------------------------------------------------
  # Synthetic accessors

  def complete?
    has_iiif_dir? && has_page_images? && has_marc_record? && has_manifest_template?
  end

  def incomplete?
    !complete?
  end

  def available?
    active? && complete? && copies_available > 0
  end

  def unavailable?
    !available?
  end

  def inactive?
    !active?
  end

  def status
    return 'Incomplete' if incomplete?

    active? ? 'Active' : 'Inactive'
  end

  def reason_unavailable
    return if available?
    return LendingItem::MSG_INACTIVE unless active?
    return LendingItem::MSG_INCOMPLETE unless complete?
    return LendingItem::MSG_UNAVAILABLE unless (due_date = next_due_date)

    date_str = due_date.to_s(:long)
    "#{LendingItem::MSG_UNAVAILABLE} It will be returned on #{date_str}"
  end

  def reason_incomplete
    return if complete?
    return MSG_NO_IIIF_DIR unless has_iiif_dir?
    return MSG_NO_PAGE_IMAGES unless has_page_images?
    return MSG_NO_MARC_XML unless has_marc_record?
    return MSG_NO_MANIFEST_TEMPLATE unless has_manifest_template?
  end

  def copies_available
    (copies - lending_item_loans.where(loan_status: :active).count)
  end

  def due_dates
    active_loans.pluck(:due_date)
  end

  def next_due_date
    return unless (next_loan_due = active_loans.first)

    next_loan_due.due_date
  end

  def iiif_manifest
    return unless has_iiif_dir? && has_page_images?

    Lending::IIIFManifest.new(title: title, author: author, dir_path: iiif_dir)
  end

  def marc_metadata
    return @marc_metadata if instance_variable_defined?(:@marc_metadata)

    @marc_metadata = load_marc_metadata
  end

  def iiif_dir
    return unless directory

    @iiif_dir ||= begin
      iiif_dir_relative = File.join(iiif_final_root, directory)
      File.absolute_path(iiif_dir_relative)
    end
  end

  def record_id
    ensure_record_id_and_barcode
    @record_id
  end

  def barcode
    ensure_record_id_and_barcode
    @barcode
  end

  # rubocop:disable Naming/PredicateName
  def has_iiif_dir?
    return false unless iiif_dir

    File.exist?(iiif_dir) && File.directory?(iiif_dir)
  end
  # rubocop:enable Naming/PredicateName

  # rubocop:disable Naming/PredicateName
  def has_page_images?
    return false unless iiif_dir

    Dir.entries(iiif_dir).any? { |e| Lending::Page.page_number?(e) }
  end
  # rubocop:enable Naming/PredicateName

  # ------------------------------------------------------------
  # Custom validators

  def correct_directory_format
    return if directory && directory.split('_').size == 2

    errors.add(:base, CGI.escapeHTML('directory should be in the format <bibliographic record id>_<item barcode>.'))
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
    lending_item_loans.active.order(:due_date)
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def load_marc_metadata
    Lending::MarcMetadata.from_file(marc_path).tap do |md|
      Rails.logger.warn("No MARC metadata found in #{marc_path}") unless md
    end
  end

  # rubocop:disable Naming/PredicateName
  def has_marc_record?
    marc_path&.file?
  end
  # rubocop:enable Naming/PredicateName

  # rubocop:disable Naming/PredicateName
  def has_manifest_template?
    iiif_manifest&.has_template?
  end
  # rubocop:enable Naming/PredicateName

  def return_loans_if_inactive
    return if active?

    lending_item_loans.find_each(&:return!)
  end

  def ensure_record_id_and_barcode
    return if @record_id && @barcode

    @record_id, @barcode = directory.split('_')
  end

  # TODO: move this to a helper
  def iiif_final_root
    LendingItem.iiif_final_root
  end

  # TODO: move this to a helper
  def image_server_base_uri
    UCBLIT::Util::URIs.uri_or_nil(Rails.application.config.image_server_base_uri).tap do |uri|
      raise ArgumentError, 'image_server_base_uri not set' unless uri
    end
  end

  def marc_path
    return unless iiif_dir
    return unless File.exist?(iiif_dir) && File.directory?(iiif_dir)

    Pathname.new(iiif_dir).join(Lending::Processor::MARC_XML_NAME)
  end
end
# rubocop:enable Metrics/ClassLength

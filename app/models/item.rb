require 'berkeley_library/util/uris'

# rubocop:disable Metrics/ClassLength
class Item < ActiveRecord::Base
  include PgSearch::Model

  # ------------------------------------------------------------
  # Relations

  has_many :loans, dependent: :destroy
  has_and_belongs_to_many :terms, after_add: :ensure_updated_at, after_remove: :ensure_updated_at

  # ------------------------------------------------------------
  # Validations

  validates :directory, presence: true
  validates_uniqueness_of :directory
  validates :title, presence: true
  validates :copies, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :correct_directory_format
  validate :active_items_have_copies
  validate :active_items_are_complete

  # ------------------------------------------------------------
  # Hooks

  after_create :set_default_term!
  before_save :set_complete_flag!
  after_find :update_complete_flag!
  before_destroy :verify_incomplete

  # ------------------------------------------------------------
  # Constants

  LOAN_DURATION_SECONDS = 2 * 3600 # TODO: make this configurable

  # TODO: Use Rails i18n
  MSG_CHECKED_OUT = 'You have already checked out this item.'.freeze
  MSG_UNAVAILABLE = 'There are no available copies of this item.'.freeze
  MSG_INCOMPLETE = 'This item has not yet been processed for viewing.'.freeze
  MSG_NOT_CHECKED_OUT = 'This item is not checked out.'.freeze
  MSG_ZERO_COPIES = 'Active items must have at least one copy.'.freeze
  MSG_INACTIVE = 'This item is not in active circulation.'.freeze
  MSG_INVALID_DIRECTORY = 'directory should be in the format <bibliographic record id>_<item barcode>.'.freeze
  MSG_NOT_CURRENT_TERM = 'This item is not available for the current term.'.freeze
  MSG_CANNOT_DELETE_COMPLETE_ITEM = 'Only incomplete items can be deleted.'.freeze

  # TODO: make this configurable
  MAX_CHECKOUTS_PER_PATRON = 1
  MSG_CHECKOUT_LIMIT_REACHED = "You may only check out #{MAX_CHECKOUTS_PER_PATRON} item at a time.".freeze

  # ------------------------------------------------------------
  # Scopes

  default_scope { order(:title) }

  scope :complete, -> { where(complete: true) }
  scope :incomplete, -> { where(complete: false) }
  scope :active, -> { complete.where(active: true) }
  scope :inactive, -> { complete.where(active: false) }

  pg_search_scope(
    :search_by_metadata,
    against: { title: 'A', author: 'B', publisher: 'C', physical_desc: 'D' },
    using: {
      tsearch: { prefix: true }
    }
  )

  # ------------------------------------------------------------
  # Class methods

  class << self
    # TODO: something more efficient and concurrent
    def scan_for_new_items!
      Lending.each_final_dir.map do |dir_path|
        basename = dir_path.basename.to_s
        next if exists?(directory: basename)

        create_from(basename)
      end.compact
    end

    # TODO: something more efficient and concurrent
    # rubocop:disable Metrics/MethodLength
    def create_from(directory)
      logger.info("Creating item for directory #{directory}")

      iiif_directory = IIIFDirectory.new(directory)
      unless (marc_metadata = iiif_directory.marc_metadata)
        logger.error("Unable to read MARC record from #{iiif_directory.marc_path}")
        return
      end

      Item.new(directory: directory, copies: 0).tap do |item|
        item.read_marc_attributes(marc_metadata)
        item.save(validate: false)
      end
    rescue ActiveRecord::RecordNotUnique => e
      logger.warn(e)
    end
    # rubocop:enable Metrics/MethodLength
  end

  # ------------------------------------------------------------
  # ActiveRecord overrides

  def reload(options = nil)
    super

    @iiif_directory = nil
  end

  # ------------------------------------------------------------
  # Hooks

  def set_default_term!
    return if terms.exists?

    if (term_for_new_items = Term.for_new_items)
      terms << term_for_new_items
    else
      logger.warn('No default term found')
    end
  end

  def set_complete_flag!
    self.complete = iiif_directory.complete?
  end

  def update_complete_flag!
    return if (directory_complete = iiif_directory.complete?) == complete

    self.complete = directory_complete
    save(validate: false)
  end

  def ensure_updated_at(*_args)
    touch if persisted?
  end

  def verify_incomplete
    update_complete_flag!
    return if incomplete?

    logger.warn('Failed to delete non-incomplete item', directory)
    errors.add(:base, MSG_CANNOT_DELETE_COMPLETE_ITEM)
    throw :abort
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

  def refresh_marc_metadata!(raise_if_missing: false)
    marc_metadata = iiif_directory.marc_metadata
    if marc_metadata.nil?
      raise ArgumentError, "No MARC record found at #{iiif_directory.marc_path}" if raise_if_missing

      return
    end

    read_marc_attributes(marc_metadata)
    save(validate: false) if changed?
    previous_changes
  end

  def read_marc_attributes(marc_metadata)
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

  def complete?
    complete
  end

  def incomplete?
    !complete?
  end

  def available?
    active? && for_current_term? && copies_available > 0 && complete?
  end

  def inactive?
    !active?
  end

  def status
    return 'Incomplete' if incomplete?

    active? ? 'Active' : 'Inactive'
  end

  def for_current_term?
    terms.current.exists?
  end

  def next_active_term
    current_or_future_terms.limit(1).take
  end

  def current_or_future_terms
    terms.current_or_future.order(:start_date)
  end

  # TODO: move these to an ItemValidator class or something
  def reason_unavailable
    return if available?
    return Item::MSG_INACTIVE unless active?
    return msg_not_current_term unless for_current_term?
    return msg_unavailable if copies_available <= 0
    return Item::MSG_INCOMPLETE unless complete?
  end

  def reason_incomplete
    iiif_directory.reason_incomplete
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

    iiif_directory.new_manifest(title: title, author: author)
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

  # ------------------------------------------------------------
  # Custom validators

  # TODO: move all of these to an ItemValidator class or something

  def correct_directory_format
    return if Lending::PathUtils::DIRNAME_RE =~ directory

    errors.add(:base, MSG_INVALID_DIRECTORY)
  end

  def active_items_have_copies
    return if inactive? || copies && copies > 0

    errors.add(:base, MSG_ZERO_COPIES)
  end

  def active_items_are_complete
    return if inactive? || complete?

    errors.add(:base, reason_incomplete)
  end

  def active_loans
    loans.active.order(:due_date)
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def msg_not_current_term
    msg = Item::MSG_NOT_CURRENT_TERM
    return msg unless (term = next_active_term)

    "#{msg} It will be available in #{term.name}."
  end

  def msg_unavailable
    msg = Item::MSG_UNAVAILABLE
    return msg unless (due_date = next_due_date)

    "#{msg} It will be returned on #{due_date.to_s(:long)}"
  end

  def ensure_record_id_and_barcode
    return if @record_id && @barcode

    @record_id, @barcode = directory.split('_')
  end
end
# rubocop:enable Metrics/ClassLength

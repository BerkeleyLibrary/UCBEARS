class LendingItemLoan < ActiveRecord::Base

  # ------------------------------------------------------------
  # Constants

  LOAN_STATUS_SCOPES = %i[pending active returned expired].freeze

  # ------------------------------------------------------------
  # Scopes

  # TODO: rename date columns to datetimes

  scope :pending, -> { where(loan_date: nil) }
  scope :active, -> { where('return_date IS NULL AND due_date > ? AND loan_date IS NOT NULL', Time.current.utc) }
  scope :returned, -> { where('return_date IS NOT NULL') }
  scope :expired, -> { where('due_date <= ? AND return_date IS NULL', Time.current.utc) }
  scope :complete, -> { where('due_date <= ? OR return_date IS NOT NULL', Time.current.utc) }

  scope :loaned_on, ->(date) do
    from_time = Time.zone.local(date.year, date.month, date.day)
    until_time = from_time + 1.days
    where('lending_item_loans.loan_date >= ? AND lending_item_loans.loan_date < ?', from_time, until_time)
  end

  # ------------------------------------------------------------
  # Relations

  belongs_to :lending_item

  # ------------------------------------------------------------
  # Validations

  validates :lending_item, presence: true
  validates :patron_identifier, presence: true
  validate :patron_can_check_out
  validate :item_available
  validate :item_active

  # ------------------------------------------------------------
  # Instance methods

  def return!
    return if return_date.present?

    update!(return_date: Time.current.utc)
  end

  # ------------------------------------------------------------
  # Synthetic accessors

  def pending?
    loan_date.nil?
  end

  def active?
    return_date.nil? && !loan_term_expired? && loan_date.present?
  end

  def returned?
    return_date.present?
  end

  def expired?
    return_date.nil? && loan_term_expired?
  end

  def complete?
    return_date.present? || loan_term_expired?
  end

  def loan_status
    LOAN_STATUS_SCOPES.find { |scope| send("#{scope}?") }
  end

  def ok_to_check_out?
    # TODO: clean this up
    lending_item.available? && !(active? || already_checked_out? || checkout_limit_reached)
  end

  def seconds_remaining
    due_date ? due_date.utc - Time.current.utc : 0
  end

  def duration
    return unless complete?

    (return_date || due_date) - loan_date
  end

  # ------------------------------------------------------------
  # Custom validation methods

  def patron_can_check_out
    return if complete?

    errors.add(:base, LendingItem::MSG_CHECKED_OUT) if already_checked_out?
    errors.add(:base, LendingItem::MSG_CHECKOUT_LIMIT_REACHED) if checkout_limit_reached
  end

  def item_available
    return if lending_item.available?
    # Don't count this loan against number of available copies
    return if lending_item.active_loans.include?(self)

    errors.add(:base, lending_item.reason_unavailable)
  end

  def item_active
    return if complete?
    return if lending_item.active?

    errors.add(:base, LendingItem::MSG_INACTIVE)
  end

  private

  def loan_term_expired?
    due_date && due_date <= Time.current.utc
  end

  def checkout_limit_reached
    other_checkouts = LendingItemLoan.active.where('lending_item_id != ? AND patron_identifier = ?', lending_item_id, patron_identifier)
    other_checkouts.count >= LendingItem::MAX_CHECKOUTS_PER_PATRON
  end

  def already_checked_out?
    LendingItemLoan.active
      .where(lending_item_id: lending_item_id, patron_identifier: patron_identifier)
      .where.not(id: id)
      .exists?
  end
end

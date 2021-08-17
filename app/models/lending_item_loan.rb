class LendingItemLoan < ActiveRecord::Base

  # ------------------------------------------------------------
  # Scopes

  scope :overdue, -> { active.where('due_date < ?', Time.current.utc) }

  # ------------------------------------------------------------
  # Relations

  belongs_to :lending_item

  # ------------------------------------------------------------
  # Attribute restrictions

  # TODO: just calculate this from dates
  enum loan_status: { pending: 'pending', active: 'active', complete: 'complete' }

  # ------------------------------------------------------------
  # Validations

  validates :lending_item, presence: true
  validates :patron_identifier, presence: true
  validate :patron_can_check_out
  validate :item_available
  validate :item_active

  # ------------------------------------------------------------
  # Callbacks

  after_find { |loan| loan.return! if loan.expired? || loan.lending_item.copies == 0 }

  # ------------------------------------------------------------
  # Instance methods

  def return!
    self.loan_status = :complete
    self.return_date = Time.now.utc

    # no_duplicate_checkouts validation can cause a SystemStackError
    # when return! is triggered from after_find
    save(validate: false)
  end

  # TODO: this should probably be "due?" or "overdue?"
  def expired?
    seconds_remaining <= 0
  end

  def ok_to_check_out?
    lending_item.available? && !(active? || duplicate_checkout || checkout_limit_reached)
  end

  def seconds_remaining
    due_date ? due_date.utc - Time.current.utc : 0
  end

  # TODO: this should probably be "expired?"
  def auto_returned?
    expired? && return_date >= due_date
  end

  # ------------------------------------------------------------
  # Custom validation methods

  def patron_can_check_out
    errors.add(:base, LendingItem::MSG_CHECKED_OUT) if duplicate_checkout
    errors.add(:base, LendingItem::MSG_CHECKOUT_LIMIT_REACHED) if checkout_limit_reached
  end

  def item_available
    return if lending_item.available?
    # Don't count this loan against number of available copies
    return if lending_item.active_loans.include?(self)

    errors.add(:base, lending_item.reason_unavailable)
  end

  def item_active
    return if lending_item.active?

    errors.add(:base, LendingItem::MSG_INACTIVE)
  end

  private

  def checkout_limit_reached
    other_checkouts.count >= LendingItem::MAX_CHECKOUTS_PER_PATRON
  end

  def other_checkouts
    conditions = <<~SQL
      patron_identifier = ? AND
      due_date > ? AND
      return_date IS NULL AND
      lending_item_id <> ?
    SQL
    LendingItemLoan.where(conditions, patron_identifier, Time.current.utc, lending_item_id)
  end

  def duplicate_checkout
    dup = LendingItemLoan.find_by(
      lending_item_id: lending_item_id,
      patron_identifier: patron_identifier,
      loan_status: 'active'
    )
    dup && dup.id != id
  end
end

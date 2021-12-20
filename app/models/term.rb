class Term < ActiveRecord::Base

  # ------------------------------------------------------------
  # Validations

  validates :name, presence: true, uniqueness: true
  validate :start_date_before_end_date

  def start_date_before_end_date
    return if start_date < end_date

    errors.add(:start_date, 'Term start date must precede end date')
  end

  # ------------------------------------------------------------
  # Scopes

  scope :current, -> { where("DATE(DATE_TRUNC('day', CURRENT_TIMESTAMP, ?)) BETWEEN start_date AND end_date", Time.zone.name) }

  # ------------------------------------------------------------
  # Synthetic accessors

  def current?
    Date.current >= start_date && Date.current <= end_date
  end

end

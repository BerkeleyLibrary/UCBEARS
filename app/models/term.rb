class Term < ActiveRecord::Base

  # ------------------------------------------------------------
  # Constants

  MSG_START_MUST_PRECEDE_END = 'Term start date must precede end date'.freeze

  # ------------------------------------------------------------
  # Items

  has_and_belongs_to_many :items

  # ------------------------------------------------------------
  # Validations

  validates :name, presence: true, uniqueness: true
  validate :start_date_before_end_date

  def start_date_before_end_date
    return if start_date < end_date

    errors.add(:start_date, MSG_START_MUST_PRECEDE_END)
  end

  # ------------------------------------------------------------
  # Scopes

  default_scope { order(start_date: :desc) }

  scope :current, -> { where("DATE(DATE_TRUNC('day', CURRENT_TIMESTAMP, ?)) BETWEEN start_date AND end_date", Time.zone.name) }
  scope :current_or_future, -> { where("end_date >= DATE(DATE_TRUNC('day', CURRENT_TIMESTAMP, ?))", Time.zone.name) }

  # ------------------------------------------------------------
  # Synthetic accessors

  def current?
    Date.current >= start_date && Date.current <= end_date
  end

  # ------------------------------------------------------------
  # Class methods

  class << self
    def for_new_items
      Settings.default_term
    end
  end

end

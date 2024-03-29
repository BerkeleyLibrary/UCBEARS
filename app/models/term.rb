class Term < ApplicationRecord

  # ------------------------------------------------------------
  # Constants

  MSG_START_MUST_PRECEDE_END = 'Term start date must precede end date'.freeze
  QUERY_SCOPES = %i[past current future].freeze

  # ------------------------------------------------------------
  # Items

  has_and_belongs_to_many :items

  # ------------------------------------------------------------
  # Validations

  validates :name, presence: true, uniqueness: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :start_date_before_end_date

  def start_date_before_end_date
    return unless start_date && end_date
    return if start_date < end_date

    errors.add(:base, MSG_START_MUST_PRECEDE_END)
  end

  # ------------------------------------------------------------
  # Scopes

  default_scope { order(start_date: :desc) }

  scope :current, -> { where("DATE(DATE_TRUNC('day', CURRENT_TIMESTAMP, ?)) BETWEEN start_date AND end_date", Time.zone.name) }
  scope :current_or_future, -> { where("end_date >= DATE(DATE_TRUNC('day', CURRENT_TIMESTAMP, ?))", Time.zone.name) }
  scope :future, -> { where("start_date > DATE(DATE_TRUNC('day', CURRENT_TIMESTAMP, ?))", Time.zone.name) }
  scope :past, -> { where("end_date < DATE(DATE_TRUNC('day', CURRENT_TIMESTAMP, ?))", Time.zone.name) }

  # ------------------------------------------------------------
  # Synthetic accessors

  def current?
    Date.current >= start_date && Date.current <= end_date
  end

  def default?
    self == Settings.default_term
  end

  # ------------------------------------------------------------
  # Class methods

  class << self
    def for_new_items
      Settings.default_term
    end
  end

end

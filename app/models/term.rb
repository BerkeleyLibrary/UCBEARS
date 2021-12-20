class Term < ActiveRecord::Base
  # ------------------------------------------------------------
  # Validations

  validates :name, presence: true, uniqueness: true
  validate :start_date_before_end_date

  def start_date_before_end_date
    return if start_date < end_date

    errors.add(:start_date, 'Term start date must precede end date')
  end
end

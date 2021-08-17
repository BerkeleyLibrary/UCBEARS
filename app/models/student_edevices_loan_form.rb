class StudentEdevicesLoanForm < Form
  ALLOWED_PATRON_AFFILIATIONS = [
    Patron::Affiliation::UC_BERKELEY
  ].freeze

  ALLOWED_PATRON_TYPES = [
    Patron::Type::UNDERGRAD,
    Patron::Type::UNDERGRAD_SLE,
    Patron::Type::GRAD_STUDENT
  ].freeze

  attr_accessor :borrow_check
  attr_accessor :display_name
  attr_accessor :edevices_check
  attr_accessor :fines_check
  attr_accessor :given_name
  attr_accessor :lending_check
  attr_accessor :patron
  attr_accessor :surname

  delegate :email, to: :patron, prefix: true
  delegate :id, to: :patron, prefix: true

  # Users must explicitly opt-in to each clause of the form.
  validates :borrow_check, :edevices_check, :fines_check, :lending_check,
            inclusion: { in: %w[checked] }

  validates :display_name,
            presence: true

  validates :patron,
            patron: {
              affiliations: ALLOWED_PATRON_AFFILIATIONS,
              types: ALLOWED_PATRON_TYPES
            },
            strict: true

  validates :given_name,
            presence: true

  validates :surname,
            presence: true

  validates :patron_email,
            email: true

  private

  def submit
    StudentEdevicesLoanJob.perform_later(patron_id)
  end
end

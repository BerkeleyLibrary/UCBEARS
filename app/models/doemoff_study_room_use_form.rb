class DoemoffStudyRoomUseForm < Form
  ALLOWED_PATRON_AFFILIATIONS = [
    Patron::Affiliation::UC_BERKELEY
    # Patron::Affiliation::COMMUNITY_COLLEGE, #including this option for when testing
  ].freeze

  # TODO(JS): There's got to be a better way to set all of the Patron::Type
  # items to ALLOWED_PATRON_TYPES
  ALLOWED_PATRON_TYPES = [
    Patron::Type::UNDERGRAD,
    Patron::Type::UNDERGRAD_SLE,
    Patron::Type::GRAD_STUDENT,
    Patron::Type::FACULTY,
    Patron::Type::MANAGER,
    Patron::Type::LIBRARY_STAFF,
    Patron::Type::STAFF,
    Patron::Type::POST_DOC,
    Patron::Type::VISITING_SCHOLAR
  ].freeze

  # Users must explicitly opt-in to each clause of the form.
  attr_accessor :borrow_check, :fines_check, :roomUse_check
  attr_accessor :display_name
  attr_accessor :patron

  delegate :email, to: :patron, prefix: true
  delegate :id, to: :patron, prefix: true
  delegate :type, to: :patron, prefix: true

  validates :borrow_check,
            :fines_check,
            :roomUse_check,
            inclusion: { in: %w[checked] }

  validates :display_name,
            presence: true

  validates :patron,
            patron: {
              affiliations: ALLOWED_PATRON_AFFILIATIONS,
              types: ALLOWED_PATRON_TYPES
            },
            strict: true

  validates :patron_email,
            email: true,
            presence: true

  private

  def submit
    DoemoffStudyRoomUseJob.perform_later(patron_id)
  end
end

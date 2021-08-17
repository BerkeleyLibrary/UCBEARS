# Allow qualified academic patrons to request scans of documents
#
# This is commonly referred to as the "AltMedia" form.
class ScanRequestForm < Form
  ALLOWED_PATRON_AFFILIATIONS = [
    Patron::Affiliation::UC_BERKELEY
  ].freeze

  ALLOWED_PATRON_TYPES = [
    Patron::Type::FACULTY,
    Patron::Type::STAFF,
    Patron::Type::LIBRARY_STAFF,
    Patron::Type::MANAGER,
    Patron::Type::VISITING_SCHOLAR
  ].freeze

  # Whether the user has opted in or out of the scanning service
  #
  # Note that in Ruby, only `nil` and `false` are falsey. Everything else,
  # including 0 and '0' and '', are truthy. Because we're dealing with an HTML
  # form, which only returns string values, we have to be careful about
  # typecasting here.
  #
  # @return [String]
  # @see http://ruby-doc.org/core-2.1.1/FalseClass.html
  attr_accessor :opt_in

  # Patron making the request
  # @return [Patron::Record]
  attr_accessor :patron

  # Display name of the patron making the request
  # @return [String]
  attr_accessor :patron_name

  # @!attribute [r] patron_email
  #   @return [String]
  delegate :email, to: :patron, prefix: true

  # @!attribute [r] patron_id
  #   @return [String]
  delegate :id, to: :patron, prefix: true

  validates :opt_in,
            inclusion: { in: %w[true false] }

  validates :patron,
            patron: {
              affiliations: ALLOWED_PATRON_AFFILIATIONS,
              types: ALLOWED_PATRON_TYPES
            },
            strict: true

  validates :patron_email,
            email: true,
            presence: true

  validates :patron_name,
            presence: true

  def self.patron_eligible?(patron)
    ALLOWED_PATRON_TYPES.include?(patron.type) &&
      ALLOWED_PATRON_AFFILIATIONS.include?(patron.affiliation)
  end

  def opted_in?
    opt_in == 'true'
  end

  private

  def submit
    if opted_in?
      ScanRequestOptInJob.perform_later(patron_id)
    else
      ScanRequestOptOutJob.perform_later(patron_id)
    end
  end
end

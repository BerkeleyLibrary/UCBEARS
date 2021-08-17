class ServiceArticleRequestForm < Form
  # @!attribute [string] article_title
  attr_accessor :article_title

  attr_accessor :author

  attr_accessor :citation

  # @!attribute [string] display_name
  attr_accessor :display_name

  attr_accessor :issn

  # Fields that are not required but can be optionally filled out by the user
  attr_accessor :pages

  # Patron making the request
  # @return [Patron::Record]
  attr_accessor :patron

  # @!attribute [string] patron_email
  attr_writer :patron_email

  attr_accessor :pub_location
  attr_accessor :pub_notes
  attr_accessor :pub_title

  # @!attribute [object] publication
  #   Stores the related article attributes to pass more easily to email job
  # @todo Make an object?
  attr_writer :publication

  # @!attribute [string] submit_email
  #  Determines where the information from the form submission is sent
  attr_writer :submit_email

  # @!attribute [string] support_email
  #  The help email address in case the user has questions or problems
  attr_accessor :support_email

  # @!attribute [string] vol
  attr_accessor :vol

  delegate :id, to: :patron, prefix: true
  delegate :notes, to: :patron, prefix: true

  validates :article_title, presence: true
  validates :display_name, presence: true
  validates :patron,
            patron: {
              note: /book scan eligible/
            },
            strict: true
  validates :patron_email, email: true
  validates :patron_id, presence: true
  validates :pub_title, presence: true
  validates :vol, presence: true

  def submit_email
    @submit_email ||= 'requests@library.berkeley.edu'
  end

  # rubocop:disable Metrics/MethodLength
  def publication
    @publication ||= {
      pub_title: pub_title,
      pub_location: pub_location,
      issn: issn,
      vol: vol,
      article_title: article_title,
      author: author,
      pages: pages,
      citation: citation,
      pub_notes: pub_notes
    }
  end
  # rubocop:enable Metrics/MethodLength

  # Cannot use the delegate method because that is for read-only attributes
  def patron_email
    @patron_email ||= @patron.email if @patron
  end

  private

  def submit
    ServiceArticleRequestJob.perform_later(
      submit_email,
      publication,
      patron_id
    )
  end
end

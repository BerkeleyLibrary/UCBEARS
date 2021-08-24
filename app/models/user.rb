# Represents a user in our system
#
# This is closely coupled to CalNet's user schema.
class User
  include ActiveModel::Model

  # ------------------------------------------------------------
  # Constants

  LENDING_ADMIN_GROUP = 'cn=edu:berkeley:org:libr:framework:LIBR-framework-lending-admins,ou=campus groups,dc=berkeley,dc=edu'.freeze

  # if we capture all the CalGroups, we'll blow out the session cookie store, so we just
  # keep the ones we care about
  KNOWN_CAL_GROUPS = [LENDING_ADMIN_GROUP].freeze

  # ------------------------------------------------------------
  # Initializer

  # @param uid The CalNet UID
  # @param affiliations Affiliations per CalNet (attribute `berkeleyEduAffiliations` e.g.
  #        `EMPLOYEE-TYPE-FACULTY`, `STUDENT-TYPE-REGISTERED`).
  # @param cal_groups CalNet LDAP groups (attribute `berkeleyEduIsMemberOf`). Note that
  #        in #from_omniauth we ignore any groups not in #KNOWN_CAL_GROUPS
  def initialize(uid: nil, borrower_token: nil, affiliations: nil, cal_groups: nil)
    super(uid: uid, affiliations: affiliations, cal_groups: cal_groups)
    @borrower_token = Lending::BorrowerToken.decode_or_create(borrower_token, uid: uid)
  end

  # ------------------------------------------------------------
  # Class methods

  class << self
    def from_omniauth(auth)
      ensure_valid_provider(auth['provider'])

      new(
        uid: auth['extra']['uid'],
        affiliations: auth['extra']['berkeleyEduAffiliations'],
        cal_groups: (auth['extra']['berkeleyEduIsMemberOf'] || []) & User::KNOWN_CAL_GROUPS
      )
    end

    def from_session(session)
      attrs = OpenStruct.new((session && session[:user]) || {})
      new(
        uid: attrs.uid,
        borrower_token: attrs.borrower_token,
        affiliations: attrs.affiliations,
        cal_groups: attrs.cal_groups
      )
    end

    private

    def ensure_valid_provider(provider)
      raise Error::InvalidAuthProviderError, provider if provider.to_sym != :calnet
    end
  end

  # ------------------------------------------------------------
  # Accessors

  # Affiliations per CalNet (attribute `berkeleyEduAffiliations` e.g.
  # `EMPLOYEE-TYPE-FACULTY`, `STUDENT-TYPE-REGISTERED`).
  #
  # Not to be confused with {Patron::Record#affiliation}, which returns
  # the patron affiliation according to the Millennium patron record
  # `PCODE1` value.
  #
  # @return [String]
  attr_accessor :affiliations

  # @return [String]
  attr_accessor :uid

  # @return [Array]
  attr_accessor :cal_groups

  # @return [Lending::BorrowerToken]
  attr_accessor :borrower_token

  # ------------------------------------------------------------
  # Instance methods

  # Whether the user was authenticated
  #
  # The user object is PORO, and we always want to be able to return it even in
  # cases where the current (anonymous) user hasn't authenticated. This method
  # is provided as a convenience to tell if the user's actually been auth'd.
  #
  # @return [Boolean]
  def authenticated?
    !uid.nil?
  end

  def ucb_faculty?
    affiliations&.include?('EMPLOYEE-TYPE-ACADEMIC')
  end

  def ucb_staff?
    affiliations&.include?('EMPLOYEE-TYPE-STAFF')
  end

  def ucb_student?
    return unless affiliations

    # 'NOT-REGISTERED' = summer session / concurrent enrollment? maybe?
    # see https://calnetweb.berkeley.edu/calnet-technologists/single-sign/cas/casify-your-web-application-or-web-server
    %w[STUDENT-TYPE-REGISTERED STUDENT-TYPE-NOT-REGISTERED].any? { |a9n| affiliations.include?(a9n) }
  end

  # Whether the user is a member of the Framework lending admin CalGroup
  # @return [Boolean]
  def lending_admin?
    cal_groups&.include?(LENDING_ADMIN_GROUP)
  end

  def borrower_id
    borrower_token.borrower_id
  end

  def inspect
    attrs = %i[uid affiliations cal_groups].map { |attr| "#{attr}: #{send(attr).inspect}" }.join(', ')
    "User@#{object_id}(#{attrs})"
  end
end

# Represents a user in our system
#
# This is closely coupled to CalNet's user schema.
class User
  include ActiveModel::Model
  include BerkeleyLibrary::Logging

  # ------------------------------------------------------------
  # Constants

  LENDING_ADMIN_GROUP = 'cn=edu:berkeley:org:libr:framework:LIBR-framework-lending-admins,ou=campus groups,dc=berkeley,dc=edu'.freeze

  # if we capture all the CalGroups, we'll blow out the session cookie store, so we just
  # keep the ones we care about
  KNOWN_CAL_GROUPS = [LENDING_ADMIN_GROUP].freeze

  # 'NOT REGISTERED' = summer session / concurrent enrollment / early in the semester
  # NOTE: CalNet docs are contradictory about whether there should be a dash after NOT,
  #       so for now we should handle both. See:
  #
  #       - https://calnetweb.berkeley.edu/calnet-technologists/ldap-directory-service/how-ldap-organized/people-ou/people-ou-affiliations#Student
  #       - see https://calnetweb.berkeley.edu/calnet-technologists/single-sign/cas/casify-your-web-application-or-web-server
  STUDENT_AFFILIATIONS = [
    'STUDENT-TYPE-REGISTERED',
    'STUDENT-TYPE-NOT REGISTERED',
    'STUDENT-TYPE-NOT-REGISTERED',
    'AFFILIATE-TYPE-VISITING STU RESEARCHER'
  ].freeze

  SESSION_ATTRS = %i[uid borrower_token affiliations cal_groups].freeze

  # ------------------------------------------------------------
  # Initializer

  # @param uid The CalNet UID
  # @param affiliations Affiliations per CalNet (attribute `berkeleyEduAffiliations` e.g.
  #        `EMPLOYEE-TYPE-FACULTY`, `STUDENT-TYPE-REGISTERED`).
  # @param cal_groups CalNet LDAP groups (attribute `berkeleyEduIsMemberOf`). Note that
  #        in #from_omniauth we ignore any groups not in #KNOWN_CAL_GROUPS
  def initialize(uid: nil, borrower_token: nil, affiliations: nil, cal_groups: nil)
    super(uid:, affiliations:, cal_groups:)
    @borrower_token = Lending::BorrowerToken.decode_or_create(borrower_token, uid:)
  end

  # ------------------------------------------------------------
  # Class methods

  class << self
    def from_omniauth(auth)
      ensure_valid_provider(auth['provider'])

      new(
        # NOTE: auth['uid'] (= <cas:user>) optionally returns either the UID, or
        #       berkeleyEduKerberosPrincipalString, depending on how the app was
        #       registered with CAS.
        uid: auth['extra']['uid'],
        affiliations: auth['extra']['berkeleyEduAffiliations'],
        cal_groups: (auth['extra']['berkeleyEduIsMemberOf'] || []) & User::KNOWN_CAL_GROUPS
      )
    end

    def from_session(session)
      attr_hash = (session && session[:user]) || {}
      new(**attr_hash.symbolize_keys.slice(*SESSION_ATTRS))
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
  attr_reader :borrower_token

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

    STUDENT_AFFILIATIONS.any? { |a9n| affiliations.include?(a9n) }
  end

  # Whether the user is a member of the Framework lending admin CalGroup
  # @return [Boolean]
  def lending_admin?
    cal_groups&.include?(LENDING_ADMIN_GROUP)
  end

  def update_borrower_token(token_str)
    if (new_token = Lending::BorrowerToken.from_string(token_str, uid:))
      @borrower_token = new_token
    else
      logger.warn("Token #{token_str.inspect} not valid for user #{uid}")
    end
  end

  def borrower_id
    borrower_token.borrower_id
  end

  def inspect
    attrs = %i[uid affiliations cal_groups borrower_token].map { |attr| "#{attr}: #{send(attr).inspect}" }.join(', ')
    "User@#{object_id}(#{attrs})"
  end
end

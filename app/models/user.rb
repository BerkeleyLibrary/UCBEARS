# Represents a user in our system
#
# This is closely coupled to CalNet's user schema.
class User
  include ActiveModel::Model

  # ------------------------------------------------------------
  # Constants

  FRAMEWORK_ADMIN_GROUP = 'cn=edu:berkeley:org:libr:framework:LIBR-framework-admins,ou=campus groups,dc=berkeley,dc=edu'.freeze
  LENDING_ADMIN_GROUP = 'cn=edu:berkeley:org:libr:framework:LIBR-framework-lending-admins,ou=campus groups,dc=berkeley,dc=edu'.freeze

  # if we capture all the CalGroups, we'll blow out the session cookie store, so we just
  # keep the ones we care about
  KNOWN_CAL_GROUPS = [User::FRAMEWORK_ADMIN_GROUP, User::LENDING_ADMIN_GROUP].freeze

  # ------------------------------------------------------------
  # Class methods

  class << self

    AUTH_EXTRA_KEYS = {
      affiliations: 'berkeleyEduAffiliations',
      cs_id: 'berkeleyEduCSID',
      department_number: 'departmentNumber',
      display_name: 'displayName',
      email: 'berkeleyEduOfficialEmail',
      employee_id: 'employeeNumber',
      given_name: 'givenName',
      student_id: 'berkeleyEduStuID',
      surname: 'surname',
      ucpath_id: 'berkeleyEduUCPathID',
      uid: 'uid'
    }.freeze

    # Returns a new user object from the given "omniauth.auth" hash. That's a
    # hash of all data returned by the auth provider (in our case, calnet).
    #
    # @see https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema OmniAuth Schema
    # @see https://git.lib.berkeley.edu/lap/altmedia/issues/16#note_5549 Sample Calnet Response
    # @see https://calnetweb.berkeley.edu/calnet-technologists/ldap-directory-service/how-ldap-organized/people-ou/people-attribute-schema CalNet LDAP
    def from_omniauth(auth)
      ensure_valid_provider(auth['provider'])

      auth_extra = auth['extra']
      params = AUTH_EXTRA_KEYS.each_with_object({}) { |(p, k), pp| pp[p] = auth_extra[k] }
      params[:uid] ||= auth['uid']
      params[:cal_groups] = (auth_extra['berkeleyEduIsMemberOf'] || []) & User::KNOWN_CAL_GROUPS

      new(**params)
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

  # "Unique identifier from Campus Solutions (Emplid)" per CalNet docs.
  # For students, should be the same value as berkeleyEduStuID.
  #
  # @see https://calnetweb.berkeley.edu/calnet-technologists/ldap-directory-service/ldap-simplification-and-standardization CalNet docs
  # @return [String]
  attr_accessor :cs_id

  # @return [String]
  attr_accessor :department_number

  # @return [String]
  attr_accessor :display_name

  # @return [String]
  attr_accessor :email

  # @return [String]
  attr_accessor :employee_id

  # @return [String]
  attr_accessor :given_name

  # @return [String]
  attr_accessor :student_id

  # @return [String]
  attr_accessor :surname

  # @return [String]
  attr_accessor :ucpath_id

  # @return [String]
  attr_accessor :uid

  # @return [Array]
  attr_accessor :cal_groups

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

  def primary_patron_record
    @primary_patron_record ||= find_primary_record
  end

  def role?(role)
    # First check if user is a hardcoded admin
    return true if FrameworkUsers.hardcoded_admin?(uid)

    # If user is not, then check if the user was added to the DB as an admin:
    user = FrameworkUsers.find_by(lcasid: uid)
    return unless user

    user.assignments.exists?(role: role)
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

  # Whether the user is a member of the Framework admin CalGroup
  # @return [Boolean]
  def framework_admin?
    cal_groups.include?(FRAMEWORK_ADMIN_GROUP)
  end

  # Whether the user is a member of the Framework lending admin CalGroup
  # @return [Boolean]
  def lending_admin?
    cal_groups&.include?(LENDING_ADMIN_GROUP)
  end

  def lending_id
    # TODO: something more secure
    uid
  end

  # ------------------------------------------------------------
  # Private methods

  private

  # The user's employee patron record
  # @return [Patron::Record, nil]
  def employee_patron_record
    @employee_patron_record ||= Patron::Record.find_if_active(employee_id)
  end

  # The user's student patron record (if they have a student ID)
  # @return [Patron::Record, nil]
  def student_patron_record
    @student_patron_record ||= Patron::Record.find_if_active(student_id)
  end

  # The user's Campus Solutions patron record (if they have a Campus Solutions ID)
  # @return [Patron::Record, nil]
  def csid_patron_record
    @csid_patron_record ||= Patron::Record.find_if_active(cs_id)
  end

  # The user's UC Path patron record (if they have a UC Path ID)
  # @return [Patron::Record, nil]
  def ucpath_patron_record
    @ucpath_patron_record ||= Patron::Record.find_if_active(ucpath_id)
  end

  def find_primary_record
    return student_patron_record if student_patron_record
    return csid_patron_record if csid_patron_record
    return ucpath_patron_record if ucpath_patron_record

    employee_patron_record
  end
end

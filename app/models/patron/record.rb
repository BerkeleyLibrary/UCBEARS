require 'net/ssh'
require 'open-uri'
require 'shellwords'
require 'patron/dump'

module Patron
  # Represents a patron record pulled from oskicat's PATRONAPI
  #
  # @see https://dev-oskicatp.berkeley.edu:54620/PATRONAPI/012158720/dump Sample Record
  class Record
    include ActiveModel::Model

    # Any two-digit year over this, and Ruby's Date.parse() will wrap back to 1969.
    MILLENNIUM_MAX_DATE = Date.new(2068, 12, 31)

    # Any two-digit year below this, and Ruby's Date.parse() will wrap ahead to 2068.
    MILLENNIUM_MIN_DATE = Date.new(1969, 1, 1)

    # The patron's affiliation code (UC Berkeley, Community College, etc.)
    # according to Millennium.
    #
    # Not to be confused with {Patron#affiliations}, which returns CalNet
    # affiliations (`berkeleyEduAffiliations`).
    #
    # @see Patron::Affiliation for a partial list of affiliate codes.
    # @return [String]
    attr_accessor :affiliation

    # The patron's manual blocks, or `nil` if there are none
    #
    # @return [String, nil]
    attr_accessor :blocks

    # The patron's email address on file
    #
    # @return [String]
    attr_accessor :email

    # The patron ID (employee, student, faculty, etc. -- can be a lot of things)
    #
    # @return [String]
    attr_accessor :id

    # The patron's name, usually in the form "LAST,FIRST"
    #
    # @return [String]
    attr_accessor :name

    # The patron's type code (undergraduate, post-doc, faculty, etc.)
    #
    # See Patron::Type for a partial list of codes.
    #
    # @return [String]
    attr_accessor :type

    # The date when the patron record expires in the Millennium account
    #
    # @return [Date]
    attr_accessor :expiration_date

    # Base URL for the Patron API.
    #
    # @return [URI]
    def api_base_url
      # TODO: make configuration less convoluted for Alma/Primo
      Record.api_base_url
    end

    # URL of the expect script used to add notes to patron records
    #
    # @return [URI]
    def expect_url
      # TODO: make configuration less convoluted for Alma/Primo
      Record.expect_url
    end

    class << self

      # Base URL for the Patron API.
      #
      # @return [URI]
      def api_base_url
        @api_base_url ||= URI.parse(
          Rails.application.config.altmedia['patron_url'] ||
            'https://dev-oskicatp.berkeley.edu:54620/PATRONAPI/'
        )
      end

      # URL of the expect script used to add notes to patron records
      #
      # @return [URI]
      def expect_url
        @expect_url ||= URI.parse(
          Rails.application.config.altmedia['expect_url'] ||
            'ssh://altmedia@vm161.lib.berkeley.edu/home/altmedia/bin/mkcallnote'
        )
      end

      # Returns the patron record for a given ID
      #
      # @return [Patron::Record]
      #
      # @raise [Error::PatronApiError] If an error occurs contacting
      #   the Patron API (commonly due to firewall issues) or if the API returns
      #   an unknown error message or if the API returns nothing.
      def find(id)
        patron_dump = Dump.from_patron_api(api_base_url, id)
        from_patron_dump(patron_dump)
      end

      # Returns the patron record for a given ID, if it exists, and
      # otherwise returns nil. Also returns nil for a nil ID.
      #
      # @return [Patron::Record, nil]
      def find_if_exists(id)
        return unless id

        find(id)
      rescue Error::PatronNotFoundError
        nil
      end

      def find_if_active(id)
        find_if_exists(id).tap do |record|
          return nil unless record && record.active?
        end
      end

      private

      # @param dump [Patron::Dump]
      def from_patron_dump(dump)
        new(
          id: dump.patron_id,
          affiliation: dump['PCODE1[p44]'],
          blocks: dump['MBLOCK[p56]'] == '-' ? nil : dump['MBLOCK[p56]'],
          email: dump['EMAIL ADDR[pz]'],
          name: dump['PATRN NAME[pn]'],
          type: dump['P TYPE[p47]'],
          notes: [*dump['NOTE[px]']].reject(&:blank?),
          expiration_date: Date.strptime(dump['EXP DATE[p43]'], '%m-%d-%y')
        )
      end

    end

    def expired?
      # missing date shouldn't happen, but if it does, err on the side of expiring
      return true unless expiration_date

      expiration_date < Date.current
    end

    def active?
      !expired?
    end

    def faculty?
      type == Patron::Type::FACULTY
    end

    def student?
      (type == Patron::Type::GRAD_STUDENT) || (type == Patron::Type::UNDERGRAD)
    end

    # Notes added to the patron record
    #
    # @return [Array]
    def notes
      @notes ||= []
    end

    # Notes added to the patron record
    # @param val The new array of notes
    # @return [Array]
    def notes=(val)
      val = [] if val.nil?
      raise ArgumentError, "Can't set Patron::Record.notes to non-array value #{val.inspect}" unless val.is_a?(Array)

      @notes = val
    end

    # Adds a note to the patron's record
    #
    # This uses the super-hacky method of executing an expect script over SSH
    # in order to perform the update. That means the application needs SSH
    # access to the user running that script. This is typically handled by,
    # simply, adding a valid authorized key to the application user's ~/.ssh.
    #
    # @param [String] note the note to add
    #
    # @todo It would be great to pull the update logic into our application,
    #   rather than relying on the expect script. That would be much more
    #   robust and easier to test/monitor/verify.
    def add_note(note)
      Rails.logger.debug "Setting note #{note.inspect} for patron #{id}"
      notes << ssh_add_note(note)
    end

    private

    def ssh_add_note(note)
      res = ssh_invoke_script(note)
      return note if res.match('Finished Successfully')

      raise StandardError, "Failed updating patron record for #{id}: #{res}"
    end

    def ssh_invoke_script(note)
      Net::SSH.start(expect_url.host, expect_url.user, non_interactive: true) do |ssh|
        command = [expect_url.path, note, id].shelljoin
        Rails.logger.debug("Executing SSH command: #{command}")
        ssh.exec!(command)
      end
    end
  end
end

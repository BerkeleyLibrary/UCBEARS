require 'request_mailer'

class ScanRequestOptInJob < PatronNoteJobBase
  queue_as :default

  NOTE_TXT = 'library book scan eligible'.freeze
  MAILER_PREFIX = 'scan_request_opt_in'.freeze

  def initialize(*arguments)
    super(*arguments, mailer_prefix: MAILER_PREFIX, note_txt: NOTE_TXT)
  end
end

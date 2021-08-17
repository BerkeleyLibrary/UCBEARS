require 'request_mailer'

class LibstaffEdevicesLoanJob < PatronNoteJobBase
  NOTE_TXT = 'Library Staff Electronic Devices eligible'.freeze
  MAILER_PREFIX = 'libdevice'.freeze

  def initialize(*arguments)
    super(*arguments, mailer_prefix: MAILER_PREFIX, note_txt: NOTE_TXT)
  end
end

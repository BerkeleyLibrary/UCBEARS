require 'request_mailer'

class GalcRequestJob < PatronNoteJobBase
  NOTE_TXT = 'GALC eligible'.freeze
  MAILER_PREFIX = 'galc'.freeze

  def initialize(*arguments)
    super(*arguments, mailer_prefix: MAILER_PREFIX, note_txt: NOTE_TXT)
  end
end

require 'request_mailer'

class DoemoffStudyRoomUseJob < PatronNoteJobBase
  NOTE_TXT = 'Doe/Moffitt study room eligible'.freeze
  MAILER_PREFIX = 'doemoff_room'.freeze

  def initialize(*arguments)
    super(*arguments, mailer_prefix: MAILER_PREFIX, note_txt: NOTE_TXT)
  end
end

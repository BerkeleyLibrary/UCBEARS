require 'request_mailer'

class StudentEdevicesLoanJob < PatronNoteJobBase
  NOTE_TXT = 'Student Electronic Devices eligible'.freeze
  MAILER_PREFIX = 'student_edevices'.freeze

  def initialize(*arguments)
    super(*arguments, mailer_prefix: MAILER_PREFIX, note_txt: NOTE_TXT)
  end
end

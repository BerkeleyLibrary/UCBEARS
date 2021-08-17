require 'request_mailer'

class ScanRequestOptOutJob < ApplicationJob
  queue_as :default

  def perform(patron_id)
    patron = Patron::Record.find(patron_id)
    RequestMailer.scan_request_opt_out_staff(patron.id, patron.name).deliver_now
    RequestMailer.scan_request_opt_out_faculty(patron.email).deliver_now
  end
end

require 'prawn'

# rubocop:disable Metrics/ClassLength
class RequestMailer < ApplicationMailer

  # Sends the AffiliateBorrowRequestForm
  def affiliate_borrow_request_form_email(borrow_request)
    @borrow_request = borrow_request

    mail(to: borrow_request.department_head_email)
  end

  # Send LibstaffEdevicesLoanRequest confirmation email to user
  def libdevice_confirmation_email(email)
    mail(to: email)
  end

  # Send email describing a failure of the LibstaffEdevicesLoanRequest job
  def libdevice_failure_email(empid, displayname, note)
    @empid = empid
    @displayname = displayname
    @note = note

    mail(to: admin_to)
  end

  def doemoff_room_confirmation_email(email)
    mail(to: email)
  end

  # Send email describing a failure of the DoemoffStudyRoomUse job
  def doemoff_room_failure_email(empid, displayname, note)
    @empid = empid
    @displayname = displayname
    @note = note

    mail(to: admin_to)
  end

  # Send ServiceArticleRequest confirmation email to user
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def service_article_confirmation_email(email, publication, patron)
    @pub_title = publication[:pub_title]
    @pub_location = publication[:pub_location]
    @issn = publication[:issn]
    @vol = publication[:vol]
    @article_title = publication[:article_title]
    @author = publication[:author]
    @pages = publication[:pages]
    @citation = publication[:citation]
    @pub_notes = publication[:pub_notes]

    @patron_name = patron.name
    @patron_email = patron.email

    mail(to: email)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Send email describing a failure of the ServiceArticleRequest job
  def service_article_failure_email(empid, displayname)
    @empid = empid
    @displayname = displayname

    mail(to: admin_to)
  end

  # Send StudentEdevicesLoanJob confirmation email to user
  def student_edevices_confirmation_email(email)
    mail(to: email)
  end

  # Send email describing a failure of the StudentEdevicesLoanJob job
  def student_edevices_failure_email(empid, displayname, note)
    @empid = empid
    @displayname = displayname
    @note = note

    mail(to: admin_to)
  end

  # Send GalcRequest confirmation email to user
  def galc_confirmation_email(email)
    mail(to: email, subject: 'GALC confirmation email')
  end

  # Send email describing a failure of the GalcRequest job
  def galc_failure_email(empid, displayname, note)
    @empid = empid
    @displayname = displayname
    @note = note

    mail(to: admin_to)
  end

  # Send email describing a failure of a ScanRequest job
  def scan_request_opt_in_failure_email(empid, displayname, note)
    @empid = empid
    @displayname = displayname
    @note = note

    mail(to: admin_to)
  end

  # Send ScanRequest confirmation email to the opted-in user
  def scan_request_opt_in_confirmation_email(email)
    mail(to: email)
  end

  def scan_request_opt_out_staff(empid, displayname)
    @empid = empid
    @displayname = displayname

    mail(cc: [admin_to, confirm_to])
  end

  def scan_request_opt_out_faculty(email)
    mail(to: email)
  end

  # Send Proxy-Borrower Card Request Instructions to user
  def proxy_borrower_request_email(proxy_request)
    @proxy_request = proxy_request
    mail(to: @proxy_request.user_email)
  end

  # Send Proxy-Borrower Card Request Alert to privdesk
  def proxy_borrower_alert_email(proxy_request)
    @proxy_request = proxy_request
    mail(to: privdesk_to)
  end

  # Send Stack Pass Request Alert to privdesk
  def stack_pass_email(stackpass_form)
    @stackpass_form = stackpass_form
    mail(to: [privdesk_to, 'mmarrow@library.berkeley.edu', 'nancylewis@berkeley.edu'], subject: 'Stack Pass Request')
  end

  # Send Stack Pass Denial to requester
  def stack_pass_denied(stackpass_form)
    @stackpass_form = stackpass_form
    mail(to: @stackpass_form.email, subject: 'Stack Pass Request - Denied')
  end

  # Send Stack Pass Approval to requester
  def stack_pass_approved(stackpass_form)
    # Generate the Approval PDF File:
    pdf = stackpass_pdf(stackpass_form)

    attachments['approval.pdf'] = pdf.render
    mail(to: stackpass_form.email, subject: 'Stack Pass Request - Approved')
  end

  # Send Reference Card Request Alert to privdesk
  def reference_card_email(reference_card_form)
    @reference_card_form = reference_card_form
    mail(to: [privdesk_to, 'mmarrow@library.berkeley.edu', 'nancylewis@berkeley.edu'], subject: 'Reference Card Request')
  end

  # Send Reference Card Denial to requester
  def reference_card_denied(reference_card_form)
    @reference_card_form = reference_card_form
    mail(to: @reference_card_form.email, subject: 'Reference Card Request - Denied')
  end

  # Send Reference Card Approval to requester
  def reference_card_approved(reference_card_form)
    # Generate the Approval PDF File:
    pdf = referencecard_pdf(reference_card_form)

    attachments['approval.pdf'] = pdf.render
    mail(to: reference_card_form.email, subject: 'Reference Card Request - Approved')
  end

  private

  # Create the Stack Pass approved PDF file
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def stackpass_pdf(stackpass_form)
    pdf = Prawn::Document.new
    pdf.move_down 10
    pdf.font_size 24
    pdf.text 'Main (Gardner) Stack Pass Approval', align: :center
    pdf.move_down 10
    pdf.font_size 12
    pdf.text 'Print out this Stack Pass or save it to your phone and bring it to the Doe Library,
              Gardner Stacks Level A along with a government-issued photo ID.', align: :center
    pdf.move_down 10
    pdf.text "Name: #{stackpass_form.name}", align: :center
    pdf.text "Date of Stack Pass: #{stackpass_form.pass_date.to_s(:short)}", align: :center
    pdf.text "Approved by: #{stackpass_form.processed_by}", align: :center
    pdf.move_down 10
    pdf.text 'University of California, Berkeley Library'

    pdf
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # Create the Reference Card approved PDF file
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def referencecard_pdf(refcard_form)
    pdf = Prawn::Document.new
    pdf.move_down 10
    pdf.font_size 24
    pdf.text 'Main (Gardner) Stack Reference Card Approval', align: :center
    pdf.move_down 10
    pdf.font_size 12
    pdf.text 'Print out or save this approval document to your phone and bring it to the Privileges
              Desk (Doe Library, Gardner Stacks Level A) along with a government-issued photo ID.', align: :center
    pdf.move_down 10
    pdf.text "Name: #{refcard_form.name}", align: :center
    pdf.text "Start date of Reference card: #{refcard_form.pass_date.to_s(:short)}", align: :center
    pdf.text "End date of Reference card: #{refcard_form.pass_date_end.to_s(:short)}", align: :center
    pdf.text "Approved by: #{refcard_form.processed_by}", align: :center
    pdf.move_down 10
    pdf.text 'University of California, Berkeley Library'

    pdf
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

end
# rubocop:enable Metrics/ClassLength

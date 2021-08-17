class ApplicationMailer < ActionMailer::Base
  default from: 'lib-noreply@berkeley.edu'

  private

  def admin_to
    Rails.application.config.altmedia['mail_admin_email']
  end

  def confirm_to
    Rails.application.config.altmedia['mail_confirm_email']
  end

  def privdesk_to
    Rails.application.config.altmedia['mail_privdesk_email']
  end
end

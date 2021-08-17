# Interceptors are classes that intercept outgoing emails
#
# Note that the Rails Guide (linked below) suggests that you must use a class
# or module, but that's not true. You can pass anything that responds to the
# #delivering_email method. The Mail documentation, also linked below, provides
# more detail.
#
# @see https://github.com/mikel/mail/blob/6bc16b4bce4fe280b19523c939b14a30e32a8ba4/lib/mail/mail.rb#L208 Mail#register_interceptor
# @see https://guides.rubyonrails.org/action_mailer_basics.html#intercepting-emails Rails Guides: Intercepting Emails
module Interceptor
  # Route emails to a mailing list for testing purposes
  #
  # This interceptor catches outgoing emails and routes them to a mailing list,
  # allowing stakeholders/QA to test email behaviors without actually sending
  # them to recipients. The original to/cc/bcc are stored in custom headers
  # named X-Original-{To,CC,BCC}, which are viewable in most mail clients.
  #
  # Enable this via ENV['INTERCEPT_EMAILS'] (see production.rb).
  #
  # @see https://support.google.com/mail/answer/29436?hl=en GMail: How to view headers
  class MailingListInterceptor
    # The email address that all outgoing emails will be routed to
    # @return [String]
    attr_accessor :mailing_list

    def initialize(mailing_list = 'lib-testmail@lists.berkeley.edu')
      @mailing_list = mailing_list
    end

    def delivering_email(mail)
      # Use headers to indicate who we would have emailed. Note that we don't add
      # this to the body so as not to mess up HTML/Text content.
      mail.header['X-Original-To'] = mail.to
      mail.header['X-Original-CC'] = mail.cc
      mail.header['X-Original-BCC'] = mail.bcc

      # Forward solely to the test list
      mail.to = mailing_list
      mail.cc = mail.bcc = ''
    end
  end
end

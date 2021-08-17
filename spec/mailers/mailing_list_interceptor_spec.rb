require 'rails_helper'
require 'mail'

describe Interceptor::MailingListInterceptor do
  mailing_list = 'mylist@example.test'

  attr_reader :interceptor

  before(:each) do
    @interceptor = Interceptor::MailingListInterceptor.new(mailing_list)
  end

  it 'should respond to :delivering_email' do
    expect(interceptor).to respond_to(:delivering_email)
  end

  it 'routes email to desired listserv' do
    original_subject = 'Framework/Mission Control Test Email'
    original_to = %w[danschmidt5189@berkeley.edu dcschmidt@berkeley.edu]
    original_cc = %w[ghill@library.berkeley.edu ethomas@berkeley.edu]
    original_bcc = 'tparks@library.berkeley.edu'
    email = Mail.new(
      subject: original_subject,
      to: original_to,
      cc: original_cc,
      bcc: original_bcc
    )
    interceptor.delivering_email(email)
    expect(email.to).to eq([mailing_list])
    expect(email.subject).to eq(original_subject)
    headers = email.header
    expect(headers['X-Original-To'].value).to eq(original_to.join(', '))
    expect(headers['X-Original-CC'].value).to eq(original_cc.join(', '))
    expect(headers['X-Original-BCC'].value).to eq(original_bcc)
  end
end

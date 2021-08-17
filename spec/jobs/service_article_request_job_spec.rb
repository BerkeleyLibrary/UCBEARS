require 'jobs_helper'

describe ServiceArticleRequestJob do
  attr_reader :patron
  attr_reader :email
  attr_reader :publication

  before(:each) do
    patron_id = '013191304'
    stub_patron_dump(patron_id)
    @patron = Patron::Record.find(patron_id)

    @email = 'requests@library.berkeley.edu'
    @publication = {
      pub_title: 'IEEE Software',
      issn: '0740-7459',
      vol: '35',
      number: '5',
      article_title: 'What the Errors Tell Us',
      author: 'M.H. Hamilton',
      pages: '32-37',
      citation: 'M. H. Hamilton, "What the Errors Tell Us," in IEEE Software, vol. 35, no. 5, pp. 32-37, September/October 2018.',
      pub_notes: 'doi: 10.1109/MS.2018.290110447'
    }
  end

  # NOTE: We can't use it_behaves_like('an email job') here b/c unlike the other jobs,
  # ServiceArticleRequestJob.perform_now takes more arguments than just the patron ID.

  it 'sends a request email' do
    expect { ServiceArticleRequestJob.perform_now(email, publication, patron.id) }.to(change { ActionMailer::Base.deliveries.count })
    request_message = ActionMailer::Base.deliveries.select { |m| m.to && m.to.include?(email) }.last
    expect(request_message).not_to be_nil
    expect(request_message.subject).to eq('Alt-Media Service - Article Request')
  end

  it 'sends a failure email in the event sending the request email fails' do
    expect { ServiceArticleRequestJob.perform_now(email, nil, patron.id) }
      .to raise_error(NoMethodError)
      .and(change { ActionMailer::Base.deliveries.count })
    admin_message = ActionMailer::Base.deliveries.select { |m| m.to && m.to.include?(ADMIN_EMAIL) }.last
    expect(admin_message).not_to be_nil
    expect(admin_message.subject).to eq('Alt-Media Service - Article Request')
  end
end

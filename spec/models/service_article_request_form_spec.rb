require 'rails_helper'

describe ServiceArticleRequestForm do
  attr_reader :form
  attr_reader :patron

  before(:each) do
    @patron = Patron::Record.new(
      id: 111_111,
      name: 'test-111111',
      type: Patron::Type::FACULTY
    )
    @form = ServiceArticleRequestForm.new(
      display_name: 'Chris Sharma',
      patron: patron,
      patron_email: 'chris@sharma.com',
      article_title: 'Es Pontas (9a+)',
      pub_title: 'King Lines',
      vol: '1'
    )
  end

  it 'validates the form' do
    patron.notes = ['book scan eligible']
    expect(form.valid?).to eq(true)
  end

  it 'checks patron eligibility' do
    patron.notes = ['some other note']
    expect { form.valid? }.to raise_error(Error::PatronNotEligibleError)
  end

  it 'requires a patron' do
    form.patron = nil
    expect { form.valid? }.to raise_error(Error::PatronNotFoundError)
  end

  it 'submits a job' do
    expected_submit_email = 'requests@library.berkeley.edu'
    expected_publication = {
      pub_title: 'King Lines',
      pub_location: nil,
      issn: nil,
      vol: '1',
      article_title: 'Es Pontas (9a+)',
      author: nil,
      pages: nil,
      citation: nil,
      pub_notes: nil
    }
    patron.notes = ['book scan eligible']
    expect { form.submit! }.to have_enqueued_job(ServiceArticleRequestJob)
      .with(expected_submit_email, expected_publication, patron.id)
  end
end

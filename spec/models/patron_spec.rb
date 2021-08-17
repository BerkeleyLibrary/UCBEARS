require 'rails_helper'

describe Patron::Record do

  describe 'defaults' do
    attr_reader :patron

    before(:each) do
      @patron = Patron::Record.new
    end

    it 'has the correct api_base_url' do
      default_api_base_url = URI.parse('https://dev-oskicatp.berkeley.edu:54620/PATRONAPI/')
      expect(Patron::Record.api_base_url).to eq(default_api_base_url)
      expect(patron.api_base_url).to eq(default_api_base_url)
    end

    it 'has the correct expect_url' do
      default_expect_url = URI.parse('ssh://altmedia@vm161.lib.berkeley.edu/home/altmedia/bin/mkcallnote')
      expect(Patron::Record.expect_url).to eq(default_expect_url)
      expect(patron.expect_url).to eq(default_expect_url)
    end
  end

  describe :find do
    it 'raises Error::PatronNotFoundError if not found' do
      bad_patron_id = 'does not exist'
      stub_patron_dump(bad_patron_id)
      expect { Patron::Record.find(bad_patron_id) }.to raise_error(Error::PatronNotFoundError)
    end

    it 'raises Error::PatronApiError in the event of an HTTP error' do
      patron_id = '12345'
      stub_patron_dump(patron_id, status: 500, body: '500 Internal Server Error')
      expect { Patron::Record.find(patron_id) }.to raise_error(Error::PatronApiError)
    end

    it 'raises Error::PatronApiError in the event of an unexpected Millennium error' do
      patron_id = '12345'
      body = <<~BODY
        <BODY>ERRNUM=1<BR>
        ERRMSG=Millennium did a bad<BR>
        </BODY>
      BODY
      stub_patron_dump(patron_id, body: body)
      expect { Patron::Record.find(patron_id) }.to raise_error(Error::PatronApiError)
    end

    describe 'patron attributes' do
      it 'reads patron 99999997' do
        stub_patron_dump('99999997')
        patron = Patron::Record.find('99999997')
        expect(patron.faculty?).to eq(false)
        expect(patron.student?).to eq(true)
        expect(patron.type).to eq(Patron::Type::UNDERGRAD)
      end

      it 'reads patron 99999891' do
        stub_patron_dump('99999891')
        patron = Patron::Record.find('99999891')
        expect(patron.affiliation).to eq(Patron::Affiliation::UC_BERKELEY)
        expect(patron.blocks).to be_nil
        expect(patron.email).to eq('test-300852@berkeley.edu')
        expect(patron.id).to eq('99999891')
        expect(patron.name).not_to be_nil
        expect(patron.notes).to eq(['20190202 library book scan eligible [sydr]', '20190101 library book scan eligible [sydr]'])
        expect(patron.type).to eq(Patron::Type::POST_DOC)
      end

      it 'reads patron 12345678' do
        stub_patron_dump('12345678')
        patron = Patron::Record.find('12345678')
        expect(patron.affiliation).to eq(Patron::Affiliation::UC_BERKELEY)
        expect(patron.blocks).to be_nil
        expect(patron.email).not_to be_nil
        expect(patron.faculty?).to eq(true)
        expect(patron.id).to eq('12345678')
        expect(patron.name).not_to be_nil
        expect(patron.notes).to eq([])
        expect(patron.student?).to eq(false)
        expect(patron.type).to eq(Patron::Type::FACULTY)
      end

      it 'reads patron 87654321' do
        stub_patron_dump('87654321')
        patron = Patron::Record.find('87654321')
        expect(patron.affiliation).to eq(Patron::Affiliation::UC_BERKELEY)
        expect(patron.blocks).not_to be_nil
        expect(patron.email).not_to be_nil
        expect(patron.id).to eq('87654321')
        expect(patron.name).not_to be_nil
        expect(patron.notes).to eq([])
        expect(patron.type).to eq(Patron::Type::FACULTY)
      end

      it 'reads patron 87651234' do
        stub_patron_dump('87651234')
        patron = Patron::Record.find('87651234')
        expect(patron.affiliation).to eq(Patron::Affiliation::UC_BERKELEY)
        expect(patron.blocks).to be_nil
        expect(patron.email).not_to be_nil
        expect(patron.id).to eq('87651234')
        expect(patron.name).not_to be_nil
        expect(patron.notes).to eq([])
        expect(patron.type).to eq(Patron::Type::VISITING_SCHOLAR)
      end

      it 'reads patron 18273645' do
        stub_patron_dump('18273645')
        patron = Patron::Record.find('18273645')
        expect(patron.affiliation).to eq(Patron::Affiliation::UC_BERKELEY)
        expect(patron.blocks).to be_nil
        expect(patron.email).not_to be_nil
        expect(patron.faculty?).to eq(false)
        expect(patron.id).to eq('18273645')
        expect(patron.name).not_to be_nil
        expect(patron.notes).to eq([])
        expect(patron.student?).to eq(true)
        expect(patron.type).to eq(Patron::Type::GRAD_STUDENT)
      end
    end
  end

  describe :add_note do
    include_context 'ssh'

    attr_reader :patron

    before :each do
      @patron = Patron::Record.new(id: '123', notes: ['foo'])
    end

    it 'adds a note' do
      new_note = 'hello'
      expected_command = ['/home/altmedia/bin/mkcallnote', new_note, patron.id].shelljoin
      expect(ssh).to receive(:exec!).with(expected_command).and_return('Finished Successfully')
      patron.add_note(new_note)
      expect(patron.notes).to eq(['foo', new_note])
    end

    it 'raises an error in the event the Expect script fails' do
      new_note = 'hello'
      expected_command = ['/home/altmedia/bin/mkcallnote', new_note, patron.id].shelljoin
      expect(ssh).to receive(:exec!).with(expected_command).and_return('Something bad happened')
      expect { patron.add_note(new_note) }.to raise_error(StandardError) # TODO: something more specific?
      expect(patron.notes).to eq(['foo'])
    end
  end

  describe :expired? do
    attr_reader :patron

    before(:each) do
      @patron = Patron::Record.new
    end

    it 'returns true for a missing expiration date' do
      expect(patron.expiration_date).to be_nil # just to be sure
      expect(patron.expired?).to eq(true)
    end

    it 'returns false for a future expiration date' do
      patron.expiration_date = Patron::Record::MILLENNIUM_MAX_DATE
      expect(patron.expired?).to eq(false)
    end

    it 'returns true for a past expiration date' do
      patron.expiration_date = Patron::Record::MILLENNIUM_MIN_DATE
      expect(patron.expired?).to eq(true)
    end
  end
end

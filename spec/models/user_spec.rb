require 'calnet_helper'

describe User do
  attr_reader :student_id
  attr_reader :student_record
  attr_reader :employee_id
  attr_reader :employee_record
  attr_reader :cs_id
  attr_reader :cs_record
  attr_reader :ucpath_id
  attr_reader :ucpath_record

  before(:each) do
    allow(Patron::Record).to receive(:find).and_raise(Error::PatronNotFoundError)

    @student_id = 1000
    @student_record = Patron::Record.new(id: student_id, expiration_date: Patron::Record::MILLENNIUM_MAX_DATE)
    allow(Patron::Record).to receive(:find).with(student_id).and_return(student_record)

    @employee_id = 2000
    @employee_record = Patron::Record.new(id: employee_id, expiration_date: Patron::Record::MILLENNIUM_MAX_DATE)
    allow(Patron::Record).to receive(:find).with(employee_id).and_return(employee_record)

    @cs_id = 3000
    @cs_record = Patron::Record.new(id: cs_id, expiration_date: Patron::Record::MILLENNIUM_MAX_DATE)
    allow(Patron::Record).to receive(:find).with(cs_id).and_return(cs_record)

    @ucpath_id = 4000
    @ucpath_record = Patron::Record.new(id: ucpath_id, expiration_date: Patron::Record::MILLENNIUM_MAX_DATE)
    allow(Patron::Record).to receive(:find).with(ucpath_id).and_return(ucpath_record)
  end

  describe :from_omniauth do
    it 'rejects invalid providers' do
      auth = { 'provider' => 'not calnet' }
      expect { User.from_omniauth(auth) }.to raise_error(Error::InvalidAuthProviderError)
    end

    it 'populates a User object' do
      auth = {
        'provider' => 'calnet',
        'extra' => {
          'berkeleyEduAffiliations' => 'expected affiliation',
          'departmentNumber' => 'expected dept. number',
          'displayName' => 'expected display name',
          'berkeleyEduOfficialEmail' => 'expected email',
          'employeeNumber' => 'expected employee ID',
          'givenName' => 'expected given name',
          'berkeleyEduStuID' => 'expected student ID',
          'surname' => 'expected surname',
          'berkeleyEduUCPathID' => 'expected UC Path ID',
          'uid' => 'expected UID'
        }
      }

      user = User.from_omniauth(auth)
      expect(user.affiliations).to eq('expected affiliation')
      expect(user.department_number).to eq('expected dept. number')
      expect(user.display_name).to eq('expected display name')
      expect(user.email).to eq('expected email')
      expect(user.employee_id).to eq('expected employee ID')
      expect(user.given_name).to eq('expected given name')
      expect(user.student_id).to eq('expected student ID')
      expect(user.surname).to eq('expected surname')
      expect(user.ucpath_id).to eq('expected UC Path ID')
      expect(user.uid).to eq('expected UID')
    end
  end

  describe :cal_groups do
    attr_reader :auth_hash

    before(:each) do
      patron_id = Patron::SAMPLE_IDS[Patron::Type::UNDERGRAD_SLE]
      @auth_hash = auth_hash_for(patron_id)
    end

    it "ignores CalGroups we don't care about" do
      user = User.from_omniauth(auth_hash)
      expect(user.cal_groups).to be_empty
    end

    it 'captures known groups' do
      User::KNOWN_CAL_GROUPS.each { |g| auth_hash['extra']['berkeleyEduIsMemberOf'] << g }
      user = User.from_omniauth(auth_hash)
      expect(user.cal_groups).to contain_exactly(*User::KNOWN_CAL_GROUPS)
    end

    describe :framework_admin? do
      let(:user) { User.from_omniauth(auth_hash) }

      it 'is false when FRAMEWORK_ADMIN_GROUP is not present' do
        expect(user.framework_admin?).to eq(false)
      end

      it 'is true when FRAMEWORK_ADMIN_GROUP is present' do
        user.cal_groups << User::FRAMEWORK_ADMIN_GROUP
        expect(user.framework_admin?).to eq(true)
      end
    end

    describe :lending_admin? do
      let(:user) { User.from_omniauth(auth_hash) }

      it 'is false when LENDING_ADMIN_GROUP is not present' do
        expect(user.lending_admin?).to eq(false)
      end

      it 'is true when LENDING_ADMIN_GROUP is present' do
        user.cal_groups << User::LENDING_ADMIN_GROUP
        expect(user.lending_admin?).to eq(true)
      end
    end
  end

  describe :authenticated? do
    it 'returns true if user has an ID' do
      user = User.new(uid: '12345')
      expect(user.authenticated?).to eq(true)
    end

    it 'returns false if user ID is nil' do
      user = User.new(uid: nil)
      expect(user.authenticated?).to eq(false)
    end
  end

  describe :primary_patron_record do
    attr_reader :user

    before(:each) do
      @user = User.new(
        student_id: student_id,
        cs_id: cs_id,
        ucpath_id: ucpath_id,
        employee_id: employee_id
      )
    end

    it 'prefers a student ID' do
      expect(user.primary_patron_record).to eq(student_record)
      [cs_id, ucpath_id, employee_id].each do |id|
        expect(Patron::Record).not_to receive(:find).with(id)
      end
    end

    it 'prefers a CSID if no student ID is present' do
      user.student_id = nil
      expect(user.primary_patron_record).to eq(cs_record)
      [ucpath_id, employee_id].each do |id|
        expect(Patron::Record).not_to receive(:find).with(id)
      end
    end

    it 'returns CS record if student record expired' do
      expect(student_record).to receive(:expired?).and_return(true)
      expect(user.primary_patron_record).to eq(cs_record)
      [ucpath_id, employee_id].each do |id|
        expect(Patron::Record).not_to receive(:find).with(id)
      end
    end

    it 'prefers a UC Path ID if no student ID or CSID is present' do
      user.student_id = nil
      user.cs_id = nil
      expect(user.primary_patron_record).to eq(ucpath_record)
      expect(Patron::Record).not_to receive(:find).with(employee_id)
    end

    it 'prefers a UC Path ID if student and CSID records expired' do
      [student_record, cs_record].each do |record|
        expect(record).to receive(:expired?).and_return(true)
      end
      expect(user.primary_patron_record).to eq(ucpath_record)
      expect(Patron::Record).not_to receive(:find).with(employee_id)
    end

    it 'falls back to an employee ID if no other ID present' do
      user.student_id = nil
      user.cs_id = nil
      user.ucpath_id = nil
      expect(user.primary_patron_record).to eq(employee_record)
    end

    it 'returns employee record if other records expired' do
      [student_record, cs_record, ucpath_record].each do |record|
        expect(record).to receive(:expired?).and_return(true)
      end
      expect(user.primary_patron_record).to eq(employee_record)
    end

    it 'returns nil if no patron records found' do
      %i[student_id cs_id ucpath_id employee_id].each do |attr|
        old_id = user.send(attr)
        user.send("#{attr}=", old_id + 1)
      end
      expect(user.primary_patron_record).to be_nil
    end

    it 'returns nil if no IDs set' do
      %i[student_id cs_id ucpath_id employee_id].each do |attr|
        user.send("#{attr}=", nil)
      end
      expect(user.primary_patron_record).to be_nil
    end

    it 'returns nil if all records expired' do
      [student_record, cs_record, ucpath_record, employee_record].each do |record|
        expect(record).to receive(:expired?).and_return(true)
      end
      expect(user.primary_patron_record).to be_nil
    end
  end
end

require 'rails_helper'

module Health

  describe Status do
    describe '&' do
      it 'handles nil' do
        expect(Status::PASS & nil).to eq(Status::PASS)
      end

      # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
      it 'handles self' do
        expect(Status::PASS & Status::PASS).to eq(Status::PASS)
        expect(Status::WARN & Status::WARN).to eq(Status::WARN)
      end
      # rubocop:enable Lint/BinaryOperatorWithIdenticalOperands

      it 'respects order' do
        expect(Status::WARN & Status::PASS).to eq(Status::WARN)
        expect(Status::PASS & Status::WARN).to eq(Status::WARN)
      end

      it 'supports &=' do
        status = Status::PASS
        status &= Status::WARN
        expect(status).to eq(Status::WARN)
      end
    end
  end
end

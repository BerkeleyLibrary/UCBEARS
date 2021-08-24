require 'rails_helper'

module Lending
  describe BorrowerToken do
    attr_reader :uid

    before(:each) do
      @uid = uid_for(:student)
    end

    describe :== do
      # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
      it 'returns true for identical objects' do
        token = BorrowerToken.new_token_for(uid)
        expect(token == token).to eq(true)
      end
      # rubocop:enable Lint/BinaryOperatorWithIdenticalOperands

      it 'returns true for equal objects' do
        token1 = BorrowerToken.new_token_for(uid)
        token2 = BorrowerToken.allocate.tap do |token|
          token.instance_variable_set(:@uid, token1.uid)
          token.instance_variable_set(:@borrower_id, token1.borrower_id)
          token.instance_variable_set(:@token_str, token1.token_str)
        end
        expect(token1 == token2).to eq(true)
        expect(token2 == token1).to eq(true)
      end

      it 'returns false for unequal objects' do
        token1 = BorrowerToken.new_token_for(uid)
        token2 = BorrowerToken.new_token_for('other uid')
        expect(token1 == token2).to eq(false)
        expect(token2 == token1).to eq(false)
      end

      it 'returns false for different tokens for the same UID' do
        token1 = BorrowerToken.new_token_for(uid)
        token2 = BorrowerToken.new_token_for(uid)
        expect(token1.borrower_id).not_to eq(token2.borrower_id) # just to be sure

        expect(token1 == token2).to eq(false)
        expect(token2 == token1).to eq(false)
      end
    end

    describe :eql? do
      it 'returns true for identical objects' do
        token = BorrowerToken.new_token_for(uid)
        expect(token.eql?(token)).to eq(true)
      end

      it 'returns true for equal objects' do
        token1 = BorrowerToken.new_token_for(uid)
        token2 = BorrowerToken.allocate.tap do |token|
          token.instance_variable_set(:@uid, token1.uid)
          token.instance_variable_set(:@borrower_id, token1.borrower_id)
          token.instance_variable_set(:@token_str, token1.token_str)
        end
        expect(token1.eql?(token2)).to eq(true)
        expect(token2.eql?(token1)).to eq(true)
      end

      it 'returns false for unequal objects' do
        token1 = BorrowerToken.new_token_for(uid)
        token2 = BorrowerToken.new_token_for('other uid')
        expect(token1.eql?(token2)).to eq(false)
        expect(token2.eql?(token1)).to eq(false)
      end

      it 'returns false for different tokens for the same UID' do
        token1 = BorrowerToken.new_token_for(uid)
        token2 = BorrowerToken.new_token_for(uid)
        expect(token1.borrower_id).not_to eq(token2.borrower_id) # just to be sure

        expect(token1.eql?(token2)).to eq(false)
        expect(token2.eql?(token1)).to eq(false)
      end
    end

    describe :new_token_for do
      it 'generates distinct tokens' do
        token1 = BorrowerToken.new_token_for(uid)
        token2 = BorrowerToken.new_token_for(uid)
        expect(token1.uid).to eq(uid)
        expect(token2.uid).to eq(uid)

        expect(token1.borrower_id).not_to eq(token2.borrower_id)
        expect(token1.token_str).not_to eq(token2.token_str)
      end
    end

    describe :from_string do
      it 'returns the token' do
        token = BorrowerToken.new_token_for(uid)
        result = BorrowerToken.from_string(token.token_str, uid: uid)
        expect(result).to eq(token)
      end

      it 'returns nil for a garbage token' do
        expect(BorrowerToken.from_string('a garbage token', uid: uid)).to be_nil
      end

      it 'returns nil for a nil token' do
        expect(BorrowerToken.from_string(nil, uid: uid)).to be_nil
      end

      it 'returns nil for a UID mismatch' do
        token = BorrowerToken.new_token_for(uid)
        expect(BorrowerToken.from_string(token.token_str, uid: 'some other UID')).to be_nil
      end
    end

    describe 'marshalling' do
      # rubocop:disable Security/MarshalLoad
      it 'marshals and unmarshals' do
        token = BorrowerToken.new_token_for(uid)
        marshalled = Marshal.dump(token)

        unmarshalled = Marshal.load(marshalled)
        expect(unmarshalled).to eq(token)
      end
      # rubocop:enable Security/MarshalLoad

      it 'does not include the borrower ID as plaintext' do
        token = BorrowerToken.new_token_for(uid)
        marshalled = Marshal.dump(token)
        expect(marshalled).not_to include(token.borrower_id)
      end
    end

    describe :as_json do
      it 'returns a string' do
        token = BorrowerToken.new_token_for(uid)
        expect(token.as_json).to be_a(String)
      end

      it 'does not include the borrower ID as plaintext' do
        token = BorrowerToken.new_token_for(uid)
        expect(token.as_json).not_to include(token.borrower_id)
      end
    end
  end
end

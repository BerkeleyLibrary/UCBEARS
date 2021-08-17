require 'rails_helper'
require 'concurrent-ruby'

ADMIN_EMAIL = Rails.application.config.altmedia['mail_admin_email']

RSpec.shared_examples 'an email job' do |email_subject_success:, confirm_cc: []|
  include_context 'ssh'
  let(:job) { described_class }

  attr_reader :patron

  before(:each) do
    patron_id = '013191304'
    stub_patron_dump(patron_id)
    @patron = Patron::Record.find(patron_id)

    # not every 'email job' needs SSH, but most do
    allow(ssh).to receive(:exec!).and_return('Finished Successfully')
  end

  it 'sends a success email to the patron' do
    expect { job.perform_now(patron.id) }.to(change { ActionMailer::Base.deliveries.count })
    patron_message = ActionMailer::Base.deliveries.select { |m| m.to && m.to.include?(patron.email) }.last
    expect(patron_message).not_to be_nil
    expect(patron_message.subject).to eq(email_subject_success)
  end

  unless confirm_cc.empty?
    it 'sends a success confirmation email to the CC list' do
      expect { job.perform_now(patron.id) }.to(change { ActionMailer::Base.deliveries.count })
      conf_message = ActionMailer::Base.deliveries.select { |m| m.cc == confirm_cc }.last
      expect(conf_message).not_to be_nil
      expect(conf_message.subject).to eq(email_subject_success)
    end
  end
end

RSpec.shared_examples 'a patron note job' do |note_text:, email_subject_failure:|
  include_context 'ssh'
  let(:job) { described_class }
  let(:patron_id) { '013191304' }

  attr_reader :patron

  before(:each) do
    stub_patron_dump(patron_id)
    @patron = Patron::Record.find(patron_id)
  end

  describe 'success' do
    let(:today) { Time.current.strftime(ApplicationJob::MILL_DATE_FORMAT) }
    let(:expected_note) { "#{today} #{note_text} [litscript]" }
    let(:expected_command) { ['/home/altmedia/bin/mkcallnote', expected_note, patron.id].shelljoin }

    it 'adds the expected note' do
      expect(ssh).to receive(:exec!).with(expected_command).and_return('Finished Successfully')
      job.perform_now(patron.id)
    end

    it 'logs before setting the note' do
      allow(ssh).to receive(:exec!).with(expected_command).and_return('Finished Successfully')
      expected_msg = "Setting note #{expected_note.inspect} for patron #{patron_id}"
      allow(Rails.logger).to receive(:debug)
      expect(Rails.logger).to receive(:debug).with(expected_msg)
      job.perform_now(patron.id)
    end

    it 'logs to the Rails logger even when running in the background' do
      allow(ssh).to receive(:exec!).with(expected_command).and_return('Finished Successfully')
      expected_msg = "Setting note #{expected_note.inspect} for patron #{patron_id}"
      allow(Rails.logger).to receive(:debug)
      expect(Rails.logger).to receive(:debug).with(expected_msg)

      latch = Concurrent::CountDownLatch.new(1)
      original_queue_adapter = job.queue_adapter
      callback_proc = -> { latch.count_down }

      # Thanks, ActiveSupport, for putting all this stuff on the job class rather
      # than the instance, so it pollutes all the other tests if we don't
      # clean it up
      begin
        job.queue_adapter = :async
        job.after_perform(&callback_proc)
        job.perform_later(patron.id)
        latch.wait(5)
      ensure
        job.queue_adapter = original_queue_adapter
        callback_chain = job.__callbacks[:perform].instance_variable_get(:@chain)
        callback = callback_chain.find { |cb| cb.instance_variable_get(:@filter) == callback_proc }
        callback_chain.delete(callback)
      end
    end
  end

  describe 'failure' do
    it 'sends a failure email in the event of an SSH error' do
      allow(ssh).to receive(:exec!).and_raise(Net::SSH::Exception)
      expect { job.perform_now(patron.id) }.to(
        raise_error(Net::SSH::Exception).and(
          (change { ActionMailer::Base.deliveries.count }).by(1)
        )
      )
      last_email = ActionMailer::Base.deliveries.last
      expect(last_email.subject).to eq(email_subject_failure)
      expect(last_email.to).to include(ADMIN_EMAIL)
    end

    it 'sends a failure email in the event of a script error' do
      allow(ssh).to receive(:exec!).and_return('Failed')
      expect { job.perform_now(patron.id) }.to(
        raise_error(StandardError).and(
          (change { ActionMailer::Base.deliveries.count }).by(1)
        )
      )
      last_email = ActionMailer::Base.deliveries.last
      expect(last_email.subject).to eq(email_subject_failure)
      expect(last_email.to).to include(ADMIN_EMAIL)
    end

    it 'logs an error in the event of an email send failure' do
      allow(ssh).to receive(:exec!).and_return('Finished Successfully')

      err_class = Net::SMTPUnknownError
      allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_raise(err_class)

      expect(Rails.logger).to receive(:error) do |msg, &block|
        msg ||= block.call
        expect(msg.to_s).to include(err_class.to_s)
      end.at_least(:once)

      expect { job.perform_now(patron.id) }.to raise_error(err_class)
    end

    it 'logs an error in the event of a patron lookup failure' do
      bad_patron_id = '2127365000'

      err_class = Error::PatronApiError
      allow(Patron::Record).to receive(:find).with(bad_patron_id).and_raise(err_class)

      expect(Rails.logger).to receive(:error) do |msg, &block|
        msg ||= block.call
        expect(msg.to_s).to include(err_class.to_s)
      end.at_least(:once) # TODO: avoid double-logging

      # Can't just use raise_error here; see https://github.com/rspec/rspec-expectations/issues/1293
      begin
        job.perform_now(bad_patron_id)
      rescue StandardError => e
        raise if e.class.name.start_with?('RSpec')

        ex = e
      end
      expect(ex).to be_a(Error::PatronApiError)
    end

    it 'logs an error in the event of an SSH error' do
      allow(ssh).to receive(:exec!).and_raise(Net::SSH::Exception)
      expect(Rails.logger).to receive(:error) do |msg|
        expect(msg).to be_a(Hash)
        expect(msg[:error]).to include(Net::SSH::Exception.to_s)
      end.ordered
      expect(Rails.logger).to receive(:error) do |msg, &block|
        expect(msg).to be_nil
        msg_actual = block.call
        expect(msg_actual).to include(job.name)
        expect(msg_actual).to include(Net::SSH::Exception.to_s)
      end.ordered
      expect { job.perform_now(patron.id) }.to raise_error(Net::SSH::Exception)
    end

    it 'logs an error in the event of a script error' do
      allow(ssh).to receive(:exec!).and_return('Failed')
      expect(Rails.logger).to receive(:error) do |msg|
        expect(msg).to be_a(Hash)
        expect(msg[:error]).to include('Failed updating patron record')
      end.ordered
      expect(Rails.logger).to receive(:error) do |msg, &block|
        expect(msg).to be_nil
        msg_actual = block.call
        expect(msg_actual).to include(job.name)
        expect(msg_actual).to include('Failed updating patron record')
      end.ordered
      expect { job.perform_now(patron.id) }.to raise_error(StandardError)
    end
  end
end

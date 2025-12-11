require 'rails_helper'

module Lending
  describe Collector do
    attr_reader :lending_root

    let(:stem) { File.basename(__FILE__, '.rb') }

    before do
      lending_root_str = Dir.mktmpdir(stem)
      @lending_root = Pathname.new(lending_root_str)
      Collector::STAGES.each { |stage| lending_root.join(stage.to_s).mkdir }
    end

    after do
      FileUtils.remove_dir(lending_root.to_s, true)
      Lending::Config.send(:reset!)
    end

    describe :collect do
      let(:sleep_interval) { 0.01 }
      let(:stop_file) { "#{stem}.stop" }

      attr_reader :collector

      def expect_to_process(item_dirname)
        ready_dir = lending_root.join('ready').join(item_dirname)
        ready_dir.mkdir

        processing_dir = lending_root.join('processing').join(item_dirname)
        expect(processing_dir).not_to exist

        final_dir = lending_root.join('final').join(item_dirname)
        expect(final_dir).not_to exist

        processor = instance_double(Processor)
        expect(Processor).to receive(:new).with(ready_dir, processing_dir).and_return(processor)

        expect(processor).to receive(:process!) do
          expect(processing_dir).to exist
        end

        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/processing.*#{item_dirname}/).ordered
        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/moving.*#{item_dirname}/).ordered
        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/triggering garbage collection/).ordered

        [processing_dir, final_dir]
      end

      before do
        @collector = Collector.new(lending_root:, stop_file:)

        allow(BerkeleyLibrary::Logging.logger).to(receive(:debug)) { |msg| warn(msg) }
      end

      it 'processes nothing if stopped' do
        collector.stop!

        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/starting/).ordered
        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/stopped/).ordered
        expect(Processor).not_to receive(:new)
        collector.collect!
      end

      it 'stops if a stop file is present' do
        stop_file_path = collector.stop_file_path
        FileUtils.touch(stop_file_path.to_s)

        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/starting/).ordered
        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/stop file .* found/).ordered
        expect(Processor).not_to receive(:new)

        collector.collect!
      end

      it 'processes files' do
        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/starting/).ordered
        processing_dir, final_dir = expect_to_process('b12345678_c12345678')
        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/nothing left to process/).ordered
        collector.collect!

        expect(processing_dir).not_to exist
        expect(final_dir).to exist
        expect(collector.stopped?).to eq(false)
      end

      it 'finds the next file' do
        processing_dirs = []
        final_dirs = []

        logger = BerkeleyLibrary::Logging.logger

        # Collect all logs in an array
        logs = []
        allow(logger).to receive(:info) { |msg| logs << msg }

        %w[b12345678_c12345678 b86753090_c86753090].each do |item_dir|
          pdir, fdir = expect_to_process(item_dir)
          processing_dirs << pdir
          final_dirs << fdir
        end

        collector.collect!

        start_index = logs.index { |l| l =~ /starting/ }
        end_index = logs.index { |l| l =~ /nothing left to process/ }

        expect(start_index).not_to be_nil
        expect(end_index).not_to be_nil
        expect(start_index).to be < end_index

        processing_dirs.each { |pdir| expect(pdir).not_to exist }
        final_dirs.each { |fdir| expect(fdir).to exist }
        expect(collector.stopped?).to eq(false)
      end

      # rubocop:disable RSpec/ExampleLength
      it 'skips single-item processing failures' do
        bad_item_dir = 'b12345678_c12345678'

        bad_ready_dir = lending_root.join('ready').join(bad_item_dir)
        bad_ready_dir.mkdir

        bad_processing_dir = lending_root.join('processing').join(bad_item_dir)
        expect(bad_processing_dir).not_to exist

        bad_final_dir = lending_root.join('final').join(bad_item_dir)

        bad_processor = instance_double(Processor)
        expect(Processor).to receive(:new).with(bad_ready_dir, bad_processing_dir).and_return(bad_processor)

        error_message = 'Oops'
        expect(bad_processor).to(receive(:process!)).and_raise(error_message)

        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/starting/).ordered
        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/processing/).ordered
        expect(BerkeleyLibrary::Logging.logger).to receive(:error).with(/Processing.*failed/, an_object_satisfying do |obj|
          obj.is_a?(Lending::ProcessingFailed)
          obj.message.include?(error_message)
        end).ordered
        # GC.start should be called even if processing fails
        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/triggering garbage collection/).ordered

        good_item_dir = 'b86753090_c86753090'
        good_processing_dir, good_final_dir = expect_to_process(good_item_dir)

        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/nothing left to process/).ordered

        collector.collect!

        expect(bad_processing_dir).to exist
        expect(bad_final_dir).not_to exist

        expect(good_processing_dir).not_to exist
        expect(good_final_dir).to exist

        expect(collector.stopped?).to eq(false)
      end
      # rubocop:enable RSpec/ExampleLength

      it 'exits cleanly in the event of some random error' do
        FileUtils.remove_dir(lending_root.to_s)

        expect(BerkeleyLibrary::Logging.logger).to receive(:info).with(/starting/).ordered
        expect(BerkeleyLibrary::Logging.logger).to receive(:error).with(/exiting due to error/, a_kind_of(StandardError))
        collector.collect!
      end
    end

    describe :from_environment do
      let(:env_vars) { [Lending::Config::ENV_ROOT, Collector::ENV_STOP_FILE] }

      before do
        @env_vals = env_vars.each_with_object({}) { |var, vals| vals[var] = ENV[var] }
      end

      after do
        @env_vals.each { |var, val| ENV[var] = val }
      end

      it 'reads the initialization info from the environment' do
        Dir.mktmpdir(File.basename(__FILE__, '.rb')) do |lending_root|
          Collector::STAGES.each do |stage|
            FileUtils.mkdir(File.join(lending_root, stage.to_s))
          end

          ENV[Lending::Config::ENV_ROOT] = lending_root
          ENV[Collector::ENV_STOP_FILE] = 'stop.stop'

          collector = Collector.from_environment
          expect(collector.lending_root.to_s).to eq(lending_root)
          expect(collector.stop_file_path.to_s).to eq(File.join(lending_root, 'stop.stop'))
        end
      end
    end
  end
end

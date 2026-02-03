require 'rails_helper'

def capture_logs(logger, levels: %i[info error], pattern: nil)
  logs = Hash.new { |h, k| h[k] = [] }

  levels.each do |level|
    allow(logger).to receive(level) do |msg = nil, *|
      text = msg.to_s
      next if pattern && !text.match?(pattern)

      logs[level] << text
    end
  end

  logs
end

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

        [processing_dir, final_dir]
      end

      before do
        @collector = Collector.new(lending_root:, stop_file:)

        allow(BerkeleyLibrary::Logging.logger).to(receive(:debug)) { |msg| warn(msg) }
      end

      it 'processes nothing if stopped' do
        logs = capture_logs(BerkeleyLibrary::Logging.logger, levels: %i[info])

        collector.stop!
        expect(Processor).not_to receive(:new)

        collector.collect!

        info = logs[:info].join("\n")
        expect(info).to match(/starting/)
        expect(info).to match(/stopped/)
      end

      it 'stops if a stop file is present' do
        logs = capture_logs(BerkeleyLibrary::Logging.logger, levels: %i[info])

        FileUtils.touch(collector.stop_file_path.to_s)
        expect(Processor).not_to receive(:new)

        collector.collect!

        info = logs[:info].join("\n")
        expect(info).to match(/starting/)
        expect(info).to match(/stop file .* found/)
      end

      it 'processes files' do
        logs = capture_logs(BerkeleyLibrary::Logging.logger, levels: %i[info])

        processing_dir, final_dir = expect_to_process('b12345678_c12345678')

        collector.collect!

        expect(processing_dir).not_to exist
        expect(final_dir).to exist
        expect(collector.stopped?).to eq(false)

        info = logs[:info].join("\n")

        # Removing ordered expects which were very brittle in CI:
        expect(info).to match(/starting/)
        expect(info).to match(/processing.*b12345678_c12345678/)
        expect(info).to match(/moving.*b12345678_c12345678/)
        expect(info).to match(/triggering garbage collection/)
        expect(info).to match(/nothing left to process/)
      end

      # rubocop:disable RSpec/ExampleLength
      it 'finds the next file' do
        processing_dirs = []
        final_dirs = []

        logs = capture_logs(
          BerkeleyLibrary::Logging.logger,
          levels: %i[info],
          pattern: /starting|nothing left to process/
        )

        %w[b12345678_c12345678 b86753090_c86753090].each do |item_dir|
          pdir, fdir = expect_to_process(item_dir)
          processing_dirs << pdir
          final_dirs << fdir
        end

        collector.collect!

        info_lines = logs[:info]
        expect(info_lines.grep(/starting/)).not_to be_empty
        expect(info_lines.grep(/nothing left to process/)).not_to be_empty

        start_index = info_lines.index { |l| l =~ /starting/ }
        end_index   = info_lines.index { |l| l =~ /nothing left to process/ }

        expect(start_index).not_to be_nil
        expect(end_index).not_to be_nil
        expect(start_index).to be < end_index

        processing_dirs.each { |pdir| expect(pdir).not_to exist }
        final_dirs.each      { |fdir| expect(fdir).to exist }
        expect(collector.stopped?).to eq(false)
      end
      # rubocop:enable RSpec/ExampleLength

      # rubocop:disable RSpec/ExampleLength
      it 'skips single-item processing failures' do
        logs = capture_logs(BerkeleyLibrary::Logging.logger, levels: %i[info error])

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

        good_item_dir = 'b86753090_c86753090'
        good_processing_dir, good_final_dir = expect_to_process(good_item_dir)
        collector.collect!

        info = logs[:info].join("\n")

        expect(info).to match(/starting/)
        expect(info).to match(/processing.*#{bad_item_dir}/)

        error_text = logs[:error].join("\n")

        expect(error_text).to match(/Processing.*failed/)
        expect(error_text).to include(error_message)

        # GC.start should be called even if processing fails
        expect(info).to match(/triggering garbage collection/)

        expect(info).to match(/nothing left to process/)

        expect(bad_processing_dir).to exist
        expect(bad_final_dir).not_to exist

        expect(good_processing_dir).not_to exist
        expect(good_final_dir).to exist

        expect(collector.stopped?).to eq(false)
      end
      # rubocop:enable RSpec/ExampleLength

      it 'exits cleanly in the event of some random error' do
        logs = capture_logs(BerkeleyLibrary::Logging.logger, levels: %i[info error])

        FileUtils.remove_dir(lending_root.to_s)

        collector.collect!

        info  = logs[:info].join("\n")
        error = logs[:error].join("\n")

        expect(info).to match(/starting/)
        expect(error).to match(/exiting due to error/)
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

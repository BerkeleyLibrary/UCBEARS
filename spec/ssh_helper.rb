require 'spec_helper'

RSpec.shared_context('ssh', shared_context: :metadata) do
  attr_reader :ssh

  before do
    @ssh = instance_double(Net::SSH::Connection::Session)
    allow(Net::SSH).to receive(:start).with('vm161.lib.berkeley.edu', 'altmedia', non_interactive: true).and_yield(ssh)
  end
end

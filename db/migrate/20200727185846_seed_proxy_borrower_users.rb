class SeedProxyBorrowerUsers < ActiveRecord::Migration[5.2]

  class ProxyBorrowerUsers < ActiveRecord::Base
    # stub to ensure migration works even w/o model class
  end

  def up
    # Clear the way!!!
    ProxyBorrowerUsers.destroy_all

    # Now insert all those beautiful users!
    ProxyBorrowerUsers.create!([
      { lcasid: 7165, name: 'Lisa Weber', role: 'Admin', email: 'lweber@library.berkeley.edu' },
      { lcasid: 304353, name: 'Mark Marrow', role: 'Admin', email: 'mmarrow@library.berkeley.edu' },
      { lcasid: 884757, name: 'Jenna Jackson', role: 'Admin', email: 'jkjackso@library.berkeley.edu' },
      { lcasid: 1588125, name: 'Sophie Rainer', role: 'Admin', email: 'sophierainer@.berkeley.edu' },
      { lcasid: 1684944, name: 'David Moles', role: 'Admin', email: 'dmoles@berkeley.edu' },
    ])
  end

  def down
    # Apparently nevermind....just remove all those users.
    ProxyBorrowerUsers.destroy_all
  end
end

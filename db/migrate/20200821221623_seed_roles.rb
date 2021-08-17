class SeedRoles < ActiveRecord::Migration[5.2]
  class Role < ActiveRecord::Base
    # stub to ensure migration works even w/o model class
  end

  def up
    say "Seeding roles database..."

    # Create initial role
    Role.create!([
      { role: 'proxyborrow_admin' },
      { role: 'stackpass_admin' }
    ])
  end

  def down
    Role.destroy_all
  end
end

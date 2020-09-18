class SeedRoles < ActiveRecord::Migration[5.2]
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

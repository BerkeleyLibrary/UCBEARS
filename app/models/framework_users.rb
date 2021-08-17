# == Schema Information
#
# Table name: framework_users
#
# lcasid :bigint   null: false
# name   :string   null: false
# role   :string   null: false   <--- NOT USED
# email  :string                 <--- NOT USED

# Model for any framework form that requires priviledged admin users

# TODO: rename to FrameworkUser (singular)
class FrameworkUsers < ActiveRecord::Base
  has_many :assignments
  has_many :roles, through: :assignments

  validates :lcasid,
            presence: true
  validates :name,
            presence: true
  validates :role,
            presence: true

  class << self
    # Hardcoded admins - so if for some reason all of the
    # admins in the DB are deleted, we still have a way of
    # getting in and managing things!
    HARDCODED_ADMIN_UIDS = [
      '7165',    # Lisa Weber
      '1684944', # David Moles
      '1707532'  # Steve Sullivan
    ].freeze

    def hardcoded_admin?(uid)
      HARDCODED_ADMIN_UIDS.include?(uid.to_s)
    end
  end

end

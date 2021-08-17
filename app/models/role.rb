class Role < ActiveRecord::Base
  has_many :assignments
  has_many :framework_users, through: :assignments

  class << self
    def proxyborrow_admin
      Role.find_or_create_by(role: 'proxyborrow_admin')
    end

    def stackpass_admin
      Role.find_or_create_by(role: 'stackpass_admin')
    end
  end
end

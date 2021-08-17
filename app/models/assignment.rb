class Assignment < ActiveRecord::Base
  belongs_to :framework_users
  belongs_to :role
end

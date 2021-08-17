require 'time'

class StackRequestsController < ApplicationController
  # TODO: do we still need this?
  def forbidden; end

  def index
    @user_is_admin = current_user.role?(Role.stackpass_admin)
  end

end

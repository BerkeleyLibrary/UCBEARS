require 'time'

class StackPassAdminController < AuthenticatedFormController
  helper_method :sort_column, :sort_direction
  before_action :require_admin!

  def admin; end

  def stackpasses
    @requests = StackPassForm.where('pass_date > ?', start_school_year).order(sort_column + ' ' + sort_direction)
  end

  def refcards
    @requests = ReferenceCardForm.where('pass_date_end > ?', start_calendar_year).order(sort_column + ' ' + sort_direction)
  end

  def users
    @users = Role.stackpass_admin.framework_users.order(:name)
  end

  def add_user
    # First check if the user exists in framework user - or create the user
    framework_user = FrameworkUsers.find_or_create_by(lcasid: params['lcasid']) do |new_user|
      new_user.name = params['name']
      new_user.role = 'Admin'
    end

    # Now that we have the user, create the assignment:
    Assignment.create(framework_users: framework_user, role: Role.stackpass_admin)

    # And redirect back to the admin users page:
    flash[:success] = "Added #{framework_user.name} as an administrator"
    redirect_to forms_stack_pass_admin_users_path
  end

  def destroy_user
    # First grab the user (so we can grab the name!)
    admin = FrameworkUsers.find(params[:id])
    admin_name = admin.name

    # Now lets find the assignment
    user_assignment = Assignment.where(framework_users: admin, role: Role.stackpass_admin).first
    user_assignment.destroy
    flash[:success] = "Removed #{admin_name} from administrator list"
    redirect_to forms_stack_pass_admin_users_path
  end

  private

  def init_form!; end

  # You shall not pass....unless you're an admin
  def require_admin!
    @user_is_admin = current_user.role?(Role.stackpass_admin)
    redirect_to stack_pass_forms_path unless @user_is_admin
  end

  def sort_column
    # only allow column names as sorting param
    StackRequest.column_names.include?(params[:sort]) ? params[:sort] : 'created_at'
  end

  def sort_direction
    # only allow asc||desc for direction param
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end

  def start_school_year
    today = Date.current
    mo = today.month
    yr = today.year
    yr -= 1 if mo < 7
    Date.new(yr, 7, 1)
  end

  def start_calendar_year
    today = Date.current
    yr = today.year
    Date.new(yr, 1, 1)
  end
end

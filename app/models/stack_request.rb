# Base class for both Stack Pass and Reference Card
# Both SP and RC offer access to the Gardner main stacks
# SP is for a single day; RC is for multiple days
class StackRequest < ActiveRecord::Base

  validates :name,
            presence: true

  validates :email,
            presence: true,
            email: true

  private

  # For Stack Pass:
  # I need to figure out the 'current school year' (July - June)
  # for the moment.... So if it's August, then July 1st of the current year
  # but if it's April, then I'd want July 1st of LAST year....
  def start_school_year
    today = Date.current
    mo = today.month
    yr = today.year
    yr -= 1 if mo < 7
    Date.new(yr, 7, 1)
  end

  # For Reference Card:
  # RC does not "reset" on a fiscal year schedule; instead
  # it resets yearly on January 1st.
  def start_calendar_year
    today = Date.current
    yr = today.year
    Date.new(yr, 1, 1)
  end

  def to_app_date(db_date)
    db_date.in_time_zone(Time.zone).to_date
  end
end

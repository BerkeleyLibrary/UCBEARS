class SessionCounter < ActiveRecord::Base
  class << self
    def increment_count_for(user)
      counter = SessionCounter.for_user(user)
      counter.increment!(:count)
    end

    def exists_for?(user)
      SessionCounter.exists?(
        uid: user.uid,
        student: user.ucb_student?,
        staff: user.ucb_staff?,
        faculty: user.ucb_faculty?,
        admin: user.lending_admin?
      )
    end

    def for_user(user)
      SessionCounter.find_or_create_by!(
        uid: user.uid,
        student: user.ucb_student?,
        staff: user.ucb_staff?,
        faculty: user.ucb_faculty?,
        admin: user.lending_admin?
      )
    end
  end
end

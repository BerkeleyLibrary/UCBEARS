class StackPassForm < StackRequest
  validate :date_check

  def submit!
    RequestMailer.stack_pass_email(self).deliver_now
  end

  def approve!
    RequestMailer.stack_pass_approved(self).deliver_now
  end

  def deny!
    RequestMailer.stack_pass_denied(self).deliver_now
  end

  def approval_count
    StackPassForm.where('email = ? AND approvedeny = ? AND pass_date >= ?', email, true, start_school_year).count
  end

  def denial_count
    StackPassForm.where('email = ? AND approvedeny = ? AND pass_date >= ?', email, false, start_school_year).count
  end

  private

  # rubocop:disable Metrics/AbcSize
  def date_check
    date_entered = pass_date || nil
    max_date = 7.days.from_now

    min_date = Date.current
    min_date = to_app_date(created_at) if created_at

    if date_entered
      errors.add(:pass_date, 'The date must not be in the past') if date_entered < min_date
      errors.add(:pass_date, 'The date must be within 7 days of today') if date_entered > max_date
    else
      errors.add(:pass_date, 'The date must not be blank and must be in the format mm/dd/yyyy')
    end
  end
  # rubocop:enable Metrics/AbcSize

end

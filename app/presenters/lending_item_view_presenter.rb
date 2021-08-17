class LendingItemViewPresenter < LendingItemPresenterBase
  attr_reader :loan

  def initialize(view_context, item, loan)
    raise ArgumentError, 'Loan cannot be nil' unless loan

    super(
      view_context,
      item,
      show_viewer: loan.active?,
      show_copyright_warning: (!loan.active? && item.available?)
    )

    @loan = loan
  end

  def action
    return action_return if loan.active?
    return action_check_out if loan.ok_to_check_out?

    tag.a(class: 'btn btn-primary disabled') { 'Check out' }.html_safe
  end

  def additional_fields
    @additional_fields ||= {}.tap do |ff|
      add_loan_info(ff) if loan.persisted?
      next if loan.active?

      ff['Available?'] = to_yes_or_no(item.available?)
      add_next_due_date(ff) unless item.available?
    end
  end

  private

  def add_loan_info(ff)
    ff['Loan status'] = loan.loan_status
    ff['Checked out'] = loan.loan_date
    ff['Due'] = loan.due_date if loan.active?
    ff['Returned'] = loan.return_date if loan.complete?
  end

  def add_next_due_date(ff)
    ff['To be returned'] = item.next_due_date if item.next_due_date
  end

  def action_return
    link_to('Return now', lending_return_path(directory: directory), class: 'btn btn-danger')
  end

  def action_check_out
    link_to('Check out', lending_check_out_path(directory: directory), class: 'btn btn-primary')
  end
end

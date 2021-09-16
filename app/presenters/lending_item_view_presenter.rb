class LendingItemViewPresenter < LendingItemPresenterBase
  attr_reader :loan

  def initialize(view_context, item, loan)
    raise ArgumentError, 'Loan cannot be nil' unless loan

    super(
      view_context,
      item,
      show_viewer: loan.active?,
    )

    @loan = loan
    @show_copyright_warning = (!loan.active? && item.available?)
  end

  def action
    return action_return if loan.active?
    return action_check_out if loan.ok_to_check_out?

    tag.a(class: 'btn primary disabled') { 'Check out' }.html_safe
  end

  def build_fields
    { 'Title' => item.title, 'Author' => item.author }.tap do |ff|
      ff.merge!(pub_metadata)
      add_circ_info(ff)
    end
  end

  def borrower_token_str
    current_user.borrower_token.token_str
  end

  protected

  def add_circ_info(ff)
    add_loan_info(ff) if loan.persisted?
    if loan.active?
      add_permalink(ff)
    else
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

  def add_permalink(ff)
    view_url = lending_view_url(directory: directory, token: borrower_token_str)
    ff['Permanent link to this checkout'] = link_to(view_url, view_url, target: '_blank')
  end

  def add_next_due_date(ff)
    ff['To be returned'] = item.next_due_date if item.next_due_date
  end

  def action_return
    link_to('Return now', lending_return_path(directory: directory), class: 'btn danger')
  end

  def action_check_out
    link_to('Check out', lending_check_out_path(directory: directory), class: 'btn primary')
  end
end

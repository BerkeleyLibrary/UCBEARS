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

    # rubocop:disable Rails/OutputSafety
    tag.a(class: 'btn primary disabled') { t('loan.actions.check_out') }.html_safe
    # rubocop:enable Rails/OutputSafety
  end

  def build_fields
    {
      t('activerecord.attributes.item.title') => item.title,
      t('activerecord.attributes.item.author') => item.author
    }.tap do |ff|
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
      ff[t('activerecord.attributes.item.available?')] = to_yes_or_no(item.available?)
      add_next_due_date(ff) unless item.available?
    end
  end

  private

  # rubocop:disable Metrics/AbcSize
  def add_loan_info(ff)
    ff[t('activerecord.attributes.loan.status')] = loan.loan_status
    ff[t('activerecord.attributes.loan.loan_date')] = loan.loan_date
    ff[t('activerecord.attributes.loan.due_date')] = loan.due_date if loan.active?
    ff[t('activerecord.attributes.loan.return_date')] = loan.return_date if loan.complete?
  end
  # rubocop:enable Metrics/AbcSize

  def add_permalink(ff)
    view_url = lending_view_url(directory: directory, token: borrower_token_str)
    ff[t('activerecord.attributes.loan.view_url')] = link_to(view_url, view_url, target: '_blank', rel: 'noopener')
  end

  def add_next_due_date(ff)
    ff[t('activerecord.attributes.item.next_due_date')] = item.next_due_date if item.next_due_date
  end

  def action_return
    button_to(t('loan.actions.return'), lending_return_path(directory: directory), class: 'btn danger', method: :get)
  end

  def action_check_out
    button_to(t('loan.actions.check_out'), lending_check_out_path(directory: directory), class: 'btn primary', method: :get)
  end
end

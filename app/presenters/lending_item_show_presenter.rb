class LendingItemShowPresenter < LendingItemPresenterBase
  def initialize(view_context, item)
    super(view_context, item, show_viewer: true)
  end

  def viewer_title
    'Preview'
  end

  def actions
    [action_edit]
  end

  def build_fields
    {
      t('activerecord.attributes.item.title') => item.title,
      t('activerecord.attributes.item.author') => item.author,
      t('activerecord.attributes.item.terms') => terms_value
    }.tap do |ff|
      ff.merge!(pub_metadata)
      ff.merge!(internal_metadata_fields)
      add_circ_metadata(ff)
    end
  end

  def terms_value
    term_names = item.terms.pluck(:name)
    return t('item.values.terms_none') unless term_names.any?

    term_names.join(', ')
  end

end

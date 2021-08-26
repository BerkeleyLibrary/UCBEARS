class LendingItemShowPresenter < LendingItemPresenterBase
  def initialize(view_context, item)
    super(view_context, item, show_viewer: true)
  end

  def viewer_title
    'Preview'
  end

  def action
    edit_action
  end

  def build_fields
    { 'Title' => item.title, 'Author' => item.author }.tap do |ff|
      ff.merge!(pub_metadata)
      ff.merge!(internal_metadata_fields)
      add_circ_metadata(ff)
    end
  end

end

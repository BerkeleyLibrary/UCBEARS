class LendingItemIndexPresenter < LendingItemShowPresenter
  LONG_FIELDS = ['IIIF directory', 'Direct link'].freeze

  def initialize(view_context, item)
    super
    # TODO: clean up class hieararchy (use mixins?) so we don't have to do this
    @show_viewer = false
  end

  def author
    marc_metadata&.author || item.author
  end

  def actions
    [edit_action, show_action, primary_action]
  end

  def marc_fields
    @marc_fields ||= marc_metadata ? marc_metadata.to_display_fields.except(*skipped_fields) : {}
  end

  def tabular_fields
    fields.except(*(marc_fields.keys + LONG_FIELDS))
  end

  def long_fields
    fields.slice(*LONG_FIELDS)
  end

  protected

  def build_fields
    super.except(*skipped_fields)
  end

  def skipped_fields
    ['Title', author_label]
  end

  private

  def primary_action
    return delete_action if item.incomplete?
    return deactivate_action if item.active?

    activate_action
  end

  def show_action
    link_to('Show', lending_show_path(directory: directory), class: 'btn btn-secondary')
  end

  def activate_action
    link_to('Make Active', lending_activate_path(directory: directory), class: 'btn btn-primary')
  end

  def deactivate_action
    link_to('Make Inactive', lending_deactivate_path(directory: directory), class: 'btn btn-warning')
  end

  def delete_action
    button_to('Delete', lending_destroy_path(directory: directory), method: :delete, class: 'btn btn-danger')
  end

  def author_label
    marc_metadata&.author_label || 'Author'
  end
end

class LendingItemIndexPresenter < LendingItemPresenterBase
  LONG_FIELDS = ['IIIF directory', 'Direct link'].freeze

  def initialize(view_context, item)
    super(view_context, item, show_viewer: false)
  end

  def actions
    [action_edit, show_action, primary_action]
  end

  def tabular_fields
    fields.except(*LONG_FIELDS)
  end

  def long_fields
    fields.slice(*LONG_FIELDS)
  end

  def build_fields
    internal_metadata_fields.tap do |ff|
      add_circ_metadata(ff)
    end
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
end

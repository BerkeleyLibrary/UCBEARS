class LendingItemIndexPresenter < LendingItemPresenterBase
  LONG_FIELDS = ['IIIF directory', 'Patron view'].freeze

  def initialize(view_context, item)
    super(view_context, item, show_viewer: false)
  end

  def actions
    [primary_action, action_edit, action_show]
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
    return action_delete if item.incomplete?
    return action_deactivate if item.active?

    action_activate
  end

  def action_show
    button_to('Admin View', lending_show_path(directory: directory), class: 'btn secondary', method: :get)
  end

  def action_activate
    button_to('Make Active', lending_activate_path(directory: directory), class: 'btn primary', method: :get)
  end

  def action_deactivate
    button_to('Make Inactive', lending_deactivate_path(directory: directory), class: 'btn danger', method: :get)
  end

  def action_delete
    button_to('Delete', lending_destroy_path(directory: directory), method: :delete, class: 'btn danger')
  end
end

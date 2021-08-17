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

  def additional_fields
    @additional_fields ||= base_additional_fields.tap do |ff|
      add_due_dates(ff)
      add_processing_metadata(ff)
      add_direct_link(ff)
    end
  end

  protected

  def edit_action
    link_to('Edit', lending_edit_path(directory: directory), class: 'btn btn-secondary')
  end

  private

  def base_additional_fields
    {
      'Record ID' => item.record_id,
      'Barcode' => item.barcode,
      'Status' => item.status,
      'Copies' => "#{item.copies_available} of #{item.copies} available"
    }
  end

  def add_processing_metadata(ff)
    if item.complete?
      ff['IIIF directory'] = item.iiif_dir
    else
      ff['Directory'] = directory
    end
  end

  def add_direct_link(ff)
    view_url = lending_view_url(directory: directory)
    ff['Direct link'] = link_to(view_url, view_url, target: '_blank')
  end

  def add_due_dates(ff)
    return if (due_dates = item.due_dates.to_a).empty?

    ff['Due'] = due_dates
  end
end

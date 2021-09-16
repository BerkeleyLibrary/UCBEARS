require 'berkeley_library/logging'

class LendingItemPresenterBase
  include BerkeleyLibrary::Logging

  attr_reader :view_context, :item

  delegate_missing_to :@view_context

  def initialize(view_context, item, show_viewer:)
    raise ArgumentError, 'Item cannot be nil' unless item

    @view_context = view_context
    @item = item
    @show_viewer = show_viewer
  end

  def title
    item.title
  end

  def author
    item.author
  end

  def show_viewer?
    @show_viewer
  end

  def fields
    @fields ||= build_fields
  end

  def viewer_title
    'View'
  end

  def to_yes_or_no(b)
    b ? 'Yes' : 'No'
  end

  def pub_metadata
    @pub_metadata ||= {
      'Publisher' => item.publisher,
      'Physical Description' => item.physical_desc
    }.filter { |_, v| !v.blank? }
  end

  def directory
    item.directory
  end

  protected

  def action_edit
    link_to('Edit item', lending_edit_path(directory: directory), class: 'btn secondary')
  end

  def internal_metadata_fields
    {
      'Record ID' => item.record_id,
      'Barcode' => item.barcode,
      'Status' => item.status,
      'Copies' => "#{item.copies_available} of #{item.copies} available"
    }
  end

  def add_circ_metadata(ff)
    add_due_dates(ff)
    add_processing_metadata(ff)
    add_direct_link(ff)
  end

  def add_due_dates(ff)
    return if (due_dates = item.due_dates.to_a).empty?

    ff['Due'] = due_dates
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
end

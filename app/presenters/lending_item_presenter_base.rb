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

  delegate :title, to: :item

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
      t('activerecord.attributes.item.publisher') => item.publisher,
      t('activerecord.attributes.item.phys_desc') => item.physical_desc
    }.filter { |_, v| v.present? }
  end

  delegate :directory, to: :item

  protected

  def t(key, **options)
    I18n.t(key, **options)
  end

  def action_edit
    button_to(t('item.actions.edit'), lending_edit_path(directory:), class: 'btn secondary', method: :get)
  end

  # rubocop:disable Metrics/AbcSize
  def internal_metadata_fields
    {
      t('activerecord.attributes.item.record_id') => item.record_id,
      t('activerecord.attributes.item.barcode') => item.barcode,
      t('activerecord.attributes.item.status') => item.status,
      t('activerecord.attributes.item.copies') => t(
        'item.values.copies_available',
        available: item.copies_available,
        total: item.copies
      )
    }.tap { |ff| add_alma_fields(ff) }
  end
  # rubocop:enable Metrics/AbcSize

  def add_circ_metadata(ff)
    add_due_dates(ff)
    add_processing_metadata(ff)
    add_direct_link(ff)
  end

  def add_due_dates(ff)
    return if (due_dates = item.due_dates.to_a).empty?

    ff[t('activerecord.attributes.loan.due_date')] = due_dates
  end

  def add_processing_metadata(ff)
    if item.complete?
      ff[t('activerecord.attributes.item.iiif_dir')] = item.iiif_directory.path
    else
      ff[t('activerecord.attributes.item.directory')] = directory
    end
  end

  def add_direct_link(ff)
    view_url = lending_view_url(directory:)
    ff[t('item.actions.patron_view')] = link_to(view_url, view_url, target: '_blank', rel: 'noopener')
  end

  def add_alma_fields(ff)
    if (alma_permalink = item.alma_permalink)
      ff['Alma MMS ID'] = item.alma_mms_id
      ff['Catalog record'] = link_to('View catalog record', alma_permalink.to_s, target: '_blank', rel: 'noopener')
    else
      ff['Alma MMS ID'] = 'Unknown'
    end
  end
end

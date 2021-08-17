require 'ucblit/logging'

class LendingItemPresenterBase
  include UCBLIT::Logging

  attr_reader :view_context, :item

  delegate_missing_to :@view_context

  def initialize(view_context, item, show_viewer:, show_copyright_warning: false)
    @view_context = view_context
    @item = item
    @show_viewer = show_viewer
    @show_copyright_warning = show_copyright_warning
  end

  def show_viewer?
    @show_viewer
  end

  def show_copyright_warning?
    @show_copyright_warning
  end

  def fields
    @fields ||= build_fields
  end

  def directory
    item.directory
  end

  def viewer_title
    'View'
  end

  def title
    marc_metadata&.title || item.title
  end

  def to_yes_or_no(b)
    b ? 'Yes' : 'No'
  end

  protected

  def build_fields
    base_fields.tap do |ff|
      ff.merge!(additional_fields) if respond_to?(:additional_fields)
    end
  end

  def marc_metadata
    @marc_metadata ||= item.marc_metadata
  end

  private

  def base_fields
    return { 'Title' => item.title, 'Author' => item.author } unless (md = marc_metadata)

    md.to_display_fields
  end
end

require 'active_support/inflector'
require 'jaro_winkler'

class TindDownloadController < ApplicationController

  # ############################################################
  # Constants

  CACHE_EXPIRY = 5.minutes

  NAME_MATCH_COUNT = 15

  # ############################################################
  # Callbacks

  before_action :authorize!

  # ############################################################
  # Configuration

  self.support_email = 'helpbox@library.berkeley.edu'

  # ############################################################
  # Actions

  def index
    render locals: { root_collections: root_collections }
  end

  # TODO: prompt w/collection name & number of records
  def download
    exporter = UCBLIT::TIND::Export.exporter_for(collection_name, export_format)
    raise ActiveRecord::RecordNotFound, "No such collection: #{collection_name}" unless exporter.any_results?

    content_type = export_format.mime_type

    # "Start" the download before we actually generate the data, so
    # it looks like something's happening
    send_file_headers!(
      type: content_type,
      filename: "#{collection_name.parameterize}.#{export_format}"
    )

    # TODO: something that doesn't require building the whole spreadsheet
    #       in memory -- make ucblit-tind use zip_tricks instead of rubyzip?
    render(body: exporter.export, content_type: content_type)
  end

  def find_collection
    collection_name = find_collection_params[:collection_name]
    render json: find_nearest(collection_name)
  end

  private

  def authorize!
    # TODO: is there a cleaner way to do this?
    return if Rails.env.development?

    authenticate! { |u| return if u.ucb_staff? }

    raise Error::ForbiddenError, "Endpoint #{controller_name}/#{action_name} is restricted to UC Berkeley staff"
  end

  # @return [Array<UCBLIT::TIND::API::Collection>] the root collections
  def root_collections
    Rails.cache.fetch(:tind_root_collections, expires_in: CACHE_EXPIRY) { UCBLIT::TIND::API::Collection.all }
  end

  def collections_by_name
    Rails.cache.fetch(:tind_collections_by_name, expires_in: CACHE_EXPIRY) do
      {}.tap do |coll_by_name|
        root_collections.each do |root|
          root.each_descendant(include_self: true) do |coll|
            coll_by_name[coll.name] = coll
          end
        end
      end
    end
  end

  def collection_names
    Rails.cache.fetch(:tind_collection_names, expires_in: CACHE_EXPIRY) { collections_by_name.keys.sort }
  end

  def find_nearest(partial_name)
    normalized_partial_name = partial_name.parameterize
    distances = [].tap do |d|
      collection_names.each do |name|
        normalized_name = name.parameterize
        distance = JaroWinkler.distance(normalized_partial_name, normalized_name)
        d << [distance, name] if normalized_name.include?(normalized_partial_name)
      end
    end
    distances = distances.sort_by { |k, v| [-k, v] }
    distances[0...NAME_MATCH_COUNT].map { |_, v| v }
  end

  def find_collection_params
    @find_collection_params ||= begin
      required_params = %i[collection_name]
      params.tap do |pp|
        pp.permit(required_params + %i[format])
        required_params.each { |p| pp.require(p) }
      end
    end
  end

  def download_params
    @download_params ||= begin
      required_params = %i[collection_name export_format]
      params.tap do |pp|
        # :format is a default parameter added from routes.rb
        # TODO: do we still need this?
        pp.permit(required_params + %i[format])
        required_params.each { |p| pp.require(p) }
      end
    end
  end

  def collection_name
    download_params[:collection_name]
  end

  # @return [UCBLIT::TIND::Export::ExportFormat] the selected format
  def export_format
    # TODO: use proper content negotiation
    return UCBLIT::TIND::Export::ExportFormat::DEFAULT unless (fmt_param = download_params[:export_format])

    UCBLIT::TIND::Export::ExportFormat.ensure_format(fmt_param)
  end

end

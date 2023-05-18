class ItemsController < ApplicationController
  before_action :set_item, only: %i[show update]
  before_action :require_lending_admin!, only: %i[update destroy processing]

  # GET /items
  # GET /items.json
  def index
    respond_to do |format|
      format.html { require_lending_admin! }

      format.json do
        authenticate!
        profile? ? paginate_items_with_profile : paginate_items
      end
    end
  end

  # GET /items/1
  # GET /items/1.json
  def show; end

  # PATCH/PUT /items/1
  # PATCH/PUT /items/1.json
  def update
    pp = item_params
    if @item.update(pp)
      render :show, status: :ok, location: @item
    else
      render_item_errors
    end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    item_id = params.require(:id)
    return unless (@item = Item.find_by(id: item_id))
    return render_item_errors(status: :forbidden) unless @item.destroy

    logger.info("Deleted item #{@item.directory} (“#{@item.title}”, id: #{item_id})")
    render body: nil, status: :no_content
  end

  # GET /processing.json
  def processing
    processing_dirs = Lending.each_processing_dir.sort_by(&:mtime).reverse
    @iiif_directories = processing_dirs.map do |dir|
      IIIFDirectory.new(dir.basename, stage: :processing)
    end
    render(:'items/iiif_directories')
  end

  private

  def paginate_items
    Item.scan_for_new_items!

    @pagy, @items = pagy(items)
    response.headers['Current-Page-Items'] = @items.count
  end

  def paginate_items_with_profile
    with_profile('items-profile.html') { paginate_items }
  end

  def items
    logger.info("query_params: #{query_params}")
    return Item.all if query_params.blank?

    query_param_hash = query_params.to_h.symbolize_keys
    logger.info("query_param_hash: #{query_param_hash}")
    ItemQueryFactory.create_query(**query_param_hash)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_item
    item_id = params.require(:id)
    @item = Item.find(item_id)
  end

  # Only allow a list of trusted parameters through.
  def item_params
    params.require(:item).permit(:directory, :title, :author, :copies, :active, :publisher, :physical_desc, term_ids: [])
  end

  def query_params
    params.permit(:active, :complete, :keywords, terms: [])
  end

  def profile?
    params.to_unsafe_h.key?(:profile)
  end

  def render_item_errors(status: :unprocessable_entity)
    logger.warn(@item.errors.full_messages)
    render('validation_errors', status:, locals: { status:, errors: @item.errors })
  end
end

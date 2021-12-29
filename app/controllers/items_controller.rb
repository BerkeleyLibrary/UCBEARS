class ItemsController < ApplicationController
  before_action :set_item, only: %i[show update destroy]
  before_action :require_lending_admin!, only: %i[index update destroy]

  # GET /items
  # GET /items.json
  def index
    Item.scan_for_new_items!
    # TODO: don't hit the DB for HTML SPA requests
    requested_items = items
    logger.info("initial query: #{requested_items}")
    @pagy, @items = pagy(requested_items)
  end

  # GET /items/1
  # GET /items/1.json
  def show; end

  # PATCH/PUT /items/1
  # PATCH/PUT /items/1.json
  def update
    if @item.update(item_params)
      render :show, status: :ok, location: @item
    else
      logger.warn(@item.errors.full_messages)
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    @item.destroy
  end

  private

  def items
    logger.info("query_params: #{query_params}")
    return Item.all unless query_params && !query_params.empty?

    query_param_hash = query_params.to_h.symbolize_keys
    logger.info("query_param_hash: #{query_param_hash}")
    ItemQuery.new(**query_param_hash)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_item
    @item = Item.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def item_params
    params.require(:item).permit(:directory, :title, :author, :copies, :active, :publisher, :physical_desc, :terms)
  end

  def query_params
    params.permit(:active, :complete, :keywords, terms: [])
  end
end

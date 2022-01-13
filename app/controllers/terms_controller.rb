class TermsController < ApplicationController
  before_action :set_term, only: %i[show update]
  before_action :require_lending_admin!, only: %i[create update destroy]

  def index
    @terms = Term.all
  end

  def show; end

  def create
    @term = Term.new(term_params)

    if @term.save
      render :show, status: :created, location: @term
    else
      render_term_errors
    end
  end

  def update
    pp = term_params
    if @term.update(pp)
      render :show, status: :ok, location: @term
    else
      render_term_errors
    end
  end

  def destroy
    term_id = params.require(:id)
    return unless (@term = Term.find_by(id: term_id))
    return render_term_errors unless @term.destroy

    logger.info("Deleted term #{@term.name} (#{@term.start_date}–#{@term.end_date})”, id: #{term_id})")
    render body: nil, status: :no_content
  end

  private

  def set_term
    term_id = params.require(:id)
    @term = Term.find(term_id)
  end

  def term_params
    params.require(:term).permit(:name, :start_date, :end_date)
  end

  def render_term_errors
    logger.warn(@term.errors.full_messages)
    render json: @term.errors, status: :unprocessable_entity
  end
end

class TermsController < ApplicationController
  before_action :set_term, only: %i[show update]
  before_action :require_lending_admin!, only: %i[create update destroy]

  def index
    respond_to do |format|
      format.html

      format.json do
        @terms = terms
      end
    end
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
    return render_term_errors(status: :forbidden) unless @term.destroy

    logger.info("Deleted term #{@term.name} (#{@term.start_date}–#{@term.end_date})”, id: #{term_id})")
    render body: nil, status: :no_content
  end

  private

  def terms
    logger.info("query_params: #{query_params}")
    return Term.all unless query_params && !query_params.empty?

    selected_scopes = Term::QUERY_SCOPES.select { |sc| query_params[sc] }
    selected_scope_relations = selected_scopes.map { |sc| Term.send(sc) }
    selected_scope_relations.inject { |r1, r2| r1.or(r2) }
  end

  def set_term
    term_id = params.require(:id)
    @term = Term.find(term_id)
  end

  def term_params
    params.require(:term).permit(:name, :start_date, :end_date)
  end

  def query_params
    params.permit(:past, :current, :future)
  end

  def render_term_errors(status: :unprocessable_entity)
    logger.warn(@term.errors.full_messages)
    render('validation_errors', status: status, locals: { status: status, errors: @term.errors })
  end
end

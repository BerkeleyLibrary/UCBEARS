class TermsController < ApplicationController
  before_action :set_term, only: %i[show update]
  before_action :require_lending_admin!, only: %i[create update destroy]

  def index
    respond_to do |format|
      format.html { require_lending_admin! }
      format.json do
        authenticate!
        @terms = terms
      end
    end
  end

  def show; end

  def create
    @term = Term.new(term_params)
    ensure_default_term!

    if @term.save
      render :show, status: :created, location: @term
    else
      render_term_errors
    end
  end

  def update
    if @term.update(term_params)
      ensure_default_term!

      render :show, status: :ok, location: @term
    else
      render_term_errors
    end
  end

  def destroy
    term_id = params.require(:id)
    return unless (@term = Term.find_by(id: term_id))
    return render_delete_default_term_forbidden(@term) if @term.default?
    return render_term_errors(status: :forbidden) unless @term.destroy

    logger.info("Deleted term #{@term.name} (#{@term.start_date}–#{@term.end_date})”, id: #{term_id})")
    render body: nil, status: :no_content
  end

  private

  # TODO: clean this up
  def ensure_default_term!
    term_default? ? set_default_term! : unset_default_term!
  end

  def set_default_term!
    return if Settings.default_term == @term

    @term.touch if @term.persisted? # adjust updated_at
    Settings.default_term = @term
  end

  def unset_default_term!
    return if Settings.default_term != @term

    @term.touch if @term.persisted?  # adjust updated_at
    Settings.default_term = nil
  end

  def terms
    return Term.all if query_params.blank?

    selected_scopes = Term::QUERY_SCOPES.select { |sc| query_params[sc] }
    selected_scope_relations = selected_scopes.map { |sc| Term.send(sc) }
    selected_scope_relations.inject { |r1, r2| r1.or(r2) }
  end

  def set_term
    term_id = params.require(:id)
    @term = Term.find(term_id)
  end

  def term_params
    params.require(:term).permit(:name, :start_date, :end_date).tap do |pp|
      logger.info("#{self.class}.term_params", pp)
    end
  end

  def term_default?
    @term_default ||= params.require(:term).permit(:default_term)[:default_term]
  end

  def query_params
    params.permit(:past, :current, :future).tap do |pp|
      logger.info("#{self.class}.query_params", pp)
    end
  end

  def render_term_errors(status: :unprocessable_entity)
    logger.warn(@term.errors.full_messages)
    render('validation_errors', status: status, locals: { status: status, errors: @term.errors })
  end

  def render_delete_default_term_forbidden(term)
    logger.warn("Can't delete default term", term)
    render('forbidden', status: :forbidden, locals: { message: t('activerecord.errors.messages.delete_default_forbidden') })
  end
end

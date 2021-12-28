class ItemQuery
  include Enumerable

  # ------------------------------------------------------------
  # Constants

  INT_RE = /(0x\h+|\d+)/
  FALSE_VALUES = ActiveModel::Type::Boolean::FALSE_VALUES

  # ------------------------------------------------------------
  # Initializer

  def initialize(active: nil, complete: nil, terms: nil, limit: nil, offset: nil)
    @active = boolean_or_nil(active)
    @complete = boolean_or_nil(complete)
    @terms = strings_or_nil(terms)
    @limit = int_or_nil(limit)
    @offset = int_or_nil(offset)
  end

  # ------------------------------------------------------------
  # Object

  def to_s
    args = []
    args << (@active ? 'active' : 'inactive') unless @active.nil?
    args << (@complete ? 'complete' : 'incomplete') unless @complete.nil?
    args << "limit: #{@limit}" if @limit
    args << "offset: #{@offset}" if @offset

    "#{self.class.name}(#{args.join(', ')})"
  end

  # ------------------------------------------------------------
  # Enumerable

  def each(&block)
    return to_enum(:each) unless block_given?

    # TODO: figure out how to query in batches while preserving order
    db_results.each(&block)
  end

  def size
    db_results.count
  end

  def exists?
    db_results.exists?
  end

  def empty?
    !exists?
  end

  def count(*args)
    db_results.count(*args)
  end

  # ------------------------------------------------------------
  # Pagination support

  def limit(n)
    ItemQuery.new(
      active: @active,
      complete: @complete,
      terms: @terms,
      limit: n,
      offset: @offset
    )
  end

  def offset(n)
    ItemQuery.new(
      active: @active,
      complete: @complete,
      terms: @terms,
      limit: @limit,
      offset: n
    )
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def db_results
    rel = @active.nil? ? Item.all : Item.where(active: @active)
    rel = rel.where(complete: @complete) unless @complete.nil?
    rel = rel.joins(:terms).where('terms.name' => @terms) if @terms
    rel = rel.limit(@limit) if @limit
    rel = rel.offset(@offset) if @offset
    rel.order(:title)
  end

  # ------------------------------
  # Attribute validation

  def boolean_or_nil(flag)
    return if flag.nil? || flag == ''

    !FALSE_VALUES.include?(flag)
  end

  def int_or_nil(opt)
    return opt if opt.is_a?(Integer)

    v_str = opt.to_s
    return Integer(v_str) if v_str =~ INT_RE
  end

  def strings_or_nil(opt)
    return unless opt.is_a?(Array)
    return if opt.empty?

    opt.map(&:to_s)
  end
end

class ItemQuery
  include Enumerable

  # ------------------------------------------------------------
  # Constants

  FALSE_VALUES = ActiveModel::Type::Boolean::FALSE_VALUES

  # ------------------------------------------------------------
  # Initializer

  def initialize(active: nil, complete: nil, limit: nil, offset: nil)
    @active = boolean_or_nil(active)
    @complete = boolean_or_nil(complete)
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
    filtered_results.each(&block)
  end

  def size
    return db_results.count unless filtered?

    db_directories.count(&method(:includes_directory?))
  end

  def exists?
    return db_results.exists? unless filtered?

    db_directories.any?(&method(:includes_directory?))
  end

  def empty?
    !exists?
  end

  def count(*args)
    return db_results.count(*args) unless filtered?
    return size if args == [:all] # pagination hack; see Pagy::Backend#pagy_get_vars

    super
  end

  # ------------------------------------------------------------
  # Pagination support

  def limit(n)
    ItemQuery.new(
      active: @active,
      complete: @complete,
      limit: n,
      offset: @offset
    )
  end

  def offset(n)
    ItemQuery.new(
      active: @active,
      complete: @complete,
      limit: @limit,
      offset: n
    )
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def filtered?
    !@complete.nil?
  end

  def filtered_results
    return db_results unless filtered?

    # TODO: figure out how to query in batches while preserving order
    db_results.select { |item| item.complete? == @complete }
  end

  def db_results
    rel = @active.nil? ? Item.all : Item.where(active: @active)

    rel = rel.order(:title)
    rel = rel.limit(@limit) if @limit
    rel = rel.offset(@offset) if @offset
    rel
  end

  def db_directories
    db_results.pluck(:directory).lazy.reject(&:nil?)
  end

  def includes_directory?(d)
    IIIFDirectory.new(d).complete? == @complete
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
    return Integer(v_str) if v_str =~ /(0x\h+|\d+)/
  end
end

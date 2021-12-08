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
  # Enumerable

  def each(&block)
    return to_enum(:each) unless block_given?

    # TODO: figure out how to query in batches while preserving order
    filtered_results.each(&block)
  end

  # ------------------------------------------------------------
  # Pagination support

  def limit(n)
    return ItemQuery.new(
      active: @active,
      complete: @complete,
      limit: n,
      offset: @offset
    )
  end

  def offset(n)
    return ItemQuery.new(
      active: @active,
      complete: @complete,
      limit: @limit,
      offset: n
    )
  end

  # ------------------------------------------------------------
  # Private methods

  private

  def filtered_results
    return db_results if complete.nil?

    # TODO: figure out how to query in batches while preserving order
    db_results.select { |item| item.complete? == @complete }
  end

  def db_results
    return Item.none unless (rel = base_relation)

    rel = rel.order(:title)
    rel = rel.limit(@limit) if @limit
    rel = rel.offset(@offset) if @offset
    rel
  end

  def base_relation
    @active.nil? ? Item.all : Item.where(active: @active)
  end

  # ------------------------------
  # Attribute validation

  def boolean_or_nil(flag)
    return nil if flag.nil? || flag == ''

    !FALSE_VALUES.include?(flag)
  end

  def int_or_nil(opt)
    return opt if opt.is_a?(Integer)

    v_str = opt.to_s
    return Integer(v_str) if v_str =~ /(0x\h+|\d+)/
  end
end
class ItemQueryFactory

  # ------------------------------------------------------------
  # Constants

  FALSE_VALUES = ActiveModel::Type::Boolean::FALSE_VALUES

  # ------------------------------------------------------------
  # Initializer

  # Initializes a new ItemQueryFactory
  #
  # @param active [Boolean, nil] true to include only active items, false to include only inactive
  # @param complete [Boolean, nil] true to include only inactive items, false to include only complete
  # @param terms [Array<String>, nil] include only items for the specified terms, by name
  # @param keywords [String, nil] include only items with metadata matching these keywords
  def initialize(active: nil, complete: nil, terms: nil, keywords: nil)
    @active = boolean_or_nil(active)
    @complete = boolean_or_nil(complete)
    @terms = strings_or_nil(terms) # TODO: use term objects or term IDs
    @keywords = keywords_or_nil(keywords)
  end

  # ------------------------------------------------------------
  # Class methods

  class << self
    # Creates a new item query.
    #
    # @param active [Boolean, nil] true to include only active items, false to include only inactive
    # @param complete [Boolean, nil] true to include only inactive items, false to include only complete
    # @param terms [Array<String>, nil] include only items for the specified terms, by name
    # @param keywords [String, nil] include only items with metadata matching these keywords
    #
    # @return [ActiveRecord::Relation] the query.
    def create_query(active: nil, complete: nil, terms: nil, keywords: nil)
      new(active:, complete:, terms:, keywords:).create
    end
  end

  # ------------------------------------------------------------
  # Instance methods

  def create
    rel = @active.nil? ? Item.all : Item.where(active: @active)
    rel = rel.where(complete: @complete) unless @complete.nil?
    if @terms
      # TODO: use term objects or term IDs
      term_ids = Term.where(name: @terms).select(:id)
      item_ids = ItemsTerm.where(term_id: term_ids).select(:item_id)
      rel = rel.where(id: item_ids)
    end
    rel = rel.search_by_metadata(@keywords) if @keywords
    rel.order(:title)
  end

  # ------------------------------------------------------------
  # Private methods

  private

  # ------------------------------
  # Attribute validation

  def boolean_or_nil(flag)
    return if flag.nil? || flag == ''

    !false?(flag)
  end

  def false?(flag)
    FALSE_VALUES.include?(flag)
  end

  def keywords_or_nil(opt)
    keywords = opt.to_s.strip
    return keywords unless keywords.empty?
  end

  def strings_or_nil(opt)
    return unless opt.is_a?(Array)
    return if opt.empty?

    opt.map(&:to_s)
  end
end

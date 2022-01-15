# Explicit model for the items_terms table that implements the
# item <-> term HABTM relation, allowing us to use it directly
# in ItemQuery
class ItemsTerm < ActiveRecord::Base; end

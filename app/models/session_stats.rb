class SessionStats
  include Comparable

  # ------------------------------------------------------------
  # Constants

  SESSION_COUNTS_BY_TYPE_SQL = <<~SQL.freeze
      SELECT student, staff, faculty, admin,
             SUM(count) AS total_sessions,
             count(DISTINCT uid) AS unique_users#{' '}
        FROM session_counters
       WHERE uid IS NOT NULL
    GROUP BY (student, staff, faculty, admin)
  SQL

  STMT_NAME_SESSION_COUNTS_BY_TYPE = 'session_counts_by_type'.freeze

  # ------------------------------------------------------------
  # Accessors

  attr_reader :types, :total_sessions, :unique_users

  # ------------------------------------------------------------
  # Initializer

  def initialize(types, total_sessions, unique_users)
    @types = types.sort
    @total_sessions = total_sessions
    @unique_users = unique_users
  end

  # ------------------------------------------------------------
  # Class methods

  class << self
    def all
      return to_enum(:all) unless block_given?

      stmt = Arel.sql(SESSION_COUNTS_BY_TYPE_SQL)
      result = connection.exec_query(stmt, STMT_NAME_SESSION_COUNTS_BY_TYPE, prepare: true)
      result.each do |result_row|
        stats = from_result(result_row)
        yield stats if stats
      end
    end

    private

    def from_result(result_row)
      types = %w[student staff faculty admin].select { |t| result_row[t] }.sort
      return if types.empty? # should never happen

      new(types, result_row['total_sessions'], result_row['unique_users'])
    end

    def connection
      ActiveRecord::Base.connection
    end
  end

  # ------------------------------------------------------------
  # Comparable

  # rubocop:disable Metrics/AbcSize
  def <=>(other)
    return unless other.is_a?(SessionStats)

    order = types.size <=> other.types.size
    return order if order != 0

    types.each_with_index do |t, i|
      order = t <=> other.types[i]
      return order if order != 0
    end

    order = total_sessions <=> other.total_sessions
    return order if order != 0

    unique_users <=> other.unique_users
  end
  # rubocop:enable Metrics/AbcSize
end

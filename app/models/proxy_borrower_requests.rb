require 'csv'

# == Schema Information
#
# Table name:  proxy_borrower_requests
# id               :bigint       not null, primary key
# faculty_name     :string       not null
# department       :string
# faculty_id       :string
# student_name     :string
# student_dsp      :string
# dsp_rep          :string
# research_last    :string       not null
# research_first   :string       not null
# research_middle  :string
# date_term        :date
# renewal          :integer      default(0)
# status           :integer      default(0)
# created_at       :datetime     not null
# updated_at       :datetime     not null
# user_email       :string
#

class ProxyBorrowerRequests < ActiveRecord::Base
  validates :research_last, presence: { message: :missing }
  validates :research_first, presence: { message: :missing }
  validate :date_limit

  def submit!
    RequestMailer.proxy_borrower_request_email(self).deliver_now
    RequestMailer.proxy_borrower_alert_email(self).deliver_now
  end

  def full_name
    full_name = "#{research_last}, #{research_first} #{research_middle}"
    full_name.gsub(/\s+$/, '')
  end

  def self.to_csv
    attributes = %w[faculty_name department student_name dsp_rep proxy_name user_email date_term date_requested]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |request|
        csv << attributes.map { |attr| request.send(attr) }
      end
    end
  end

  private

  def date_requested
    created_at.in_time_zone.to_s(:export)
  end

  # Export also wants the proxy name in one field (first last):
  def proxy_name
    proxy_name = "#{research_first} #{research_middle} #{research_last}"
    proxy_name.gsub(/\s+/, ' ')
  end

  def date_limit
    return errors.add(:date_term, :missing) unless date_term.present?
    return errors.add(:date_term, :expired) if date_term < Date.current
    return errors.add(:date_term, :too_long, max_term: max_term.to_s(:export)) if date_term > max_term
  end

  def max_term
    today = Date.current

    # If month is Jan - March, then max date is June 30th of the current year
    # else, if month is April - December, max date is June 30th of the following year
    yr = today.year
    yr += 1 if today.month >= 4

    Date.new(yr, 6, 30)
  end
end

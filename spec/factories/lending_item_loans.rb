FactoryBot.define do
  factory :lending_item_loan, aliases: %i[active_loan] do
    item_id { 1 }
    patron_identifier { BorrowerToken.next_borrower_id }
    loan_date { Time.current.utc }
    due_date { loan_date + Item::LOAN_DURATION_SECONDS.seconds }

    factory :completed_loan do
      loan_date { Time.current.utc - rand(1..7).days }
      return_date { loan_date + rand(5..30).minutes }
    end

    factory :expired_loan do
      loan_date { Time.current.utc - rand(1..7).days }
    end
  end
end

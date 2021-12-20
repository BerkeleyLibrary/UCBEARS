FactoryBot.define do
  factory :term do
    name { "Fall 2021" }
    start_date { Date.new(2021, 8, 25) }
    end_date { Date.new(2021, 12, 17) }
  end
end

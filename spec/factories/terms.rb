FactoryBot.define do
  factory :term, aliases: %i[term_fall_2021] do
    name { 'Fall 2021' }
    start_date { Date.new(2021, 8, 18) }
    end_date { Date.new(2021, 12, 17) }

    factory :term_spring_2022 do
      name { 'Spring 2022' }

      start_date { Date.new(2022, 1, 11) }
      end_date { Date.new(2022, 5, 13) }
    end

    factory :term_past do
      name { 'Past test term' }

      start_date { Date.current - 3.months }
      end_date { Date.current - 1.months }
    end

    factory :term_current do
      name { 'Current test term' }

      start_date { Date.current - 1.months }
      end_date { Date.current + 1.months }
    end

    factory :term_future do
      name { 'Future test term' }

      start_date { Date.current + 1.months }
      end_date { Date.current + 3.months }
    end
  end
end

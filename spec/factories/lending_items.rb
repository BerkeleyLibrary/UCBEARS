FactoryBot.define do
  factory :lending_item, aliases: [:item, :incomplete_item] do
    directory { 'b155001346_C044219363' }
    title { 'Villette' }
    author { 'Brontë, Charlotte' }
    copies { 0 }
    active { false }

    factory :complete_item do
      directory { 'B135491460_C106083325' }
      title { 'Cultural atlas of Ancient Egypt' }
      author { 'Baines, John' }
    end

    factory :active_item do
      directory { 'b135297126_C068087930' }
      title { 'The great depression in Europe, 1929-1939' }
      author { 'Clavin, Patricia.' }
      copies { 3 }
      active { true }
    end
  end
end

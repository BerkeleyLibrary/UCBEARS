FactoryBot.define do
  factory :lending_item, aliases: %i[item active_item] do

    directory { 'b135297126_C068087930' }
    title { 'The great depression in Europe, 1929-1939' }
    author { 'Clavin, Patricia.' }
    copies { 3 }
    active { true }

    factory :complete_item, aliases: %i[inactive_item] do
      directory { 'B135491460_C106083325' }
      title { 'Cultural atlas of Ancient Egypt' }
      author { 'Baines, John' }
      copies { 0 }
      active { false }
    end

    factory :incomplete_item, aliases: %i[incomplete_no_directory] do
      directory { 'b155001346_C044219363' }
      title { 'Villette' }
      author { 'Brontë, Charlotte' }
      copies { 0 }
      active { false }
    end

    factory :incomplete_no_images do
      directory { 'b18357550_C106160623' }
      title { 'Herakleides : a portrait mummy from Roman Egypt' }
      author { 'Corcoran, Lorelei Hilda, 1953-' }
      copies { 2 }
      active { true }
    end

    factory :incomplete_no_manifest do
      directory { 'b23752729_C118406204' }
      title { 'Art of Mesopotamia' }
      author { 'Bahrani, Zainab' }
    end

    factory :incomplete_no_marc do
      directory { 'b135297126_BT 7 064 812' }
      title { 'The great depression in Europe, 1929-1939' }
      author { 'Clavin, Patricia.' }
    end

    factory :incomplete_marc_only do
      directory { 'b11996535_B 3 106 704' }
      title { 'Pamphlet' }
      author { 'Canada. Department of Agriculture.' }
    end
  end
end

FactoryBot.define do
  factory :item, aliases: %i[active_item] do

    directory { 'b135297126_C068087930' }
    title { 'The great depression in Europe, 1929-1939' }
    author { 'Clavin, Patricia.' }
    publisher { "New York : St. Martin's Press, 2000." }
    physical_desc { 'viii, 244 p. : ill. ; 23 cm.' }
    copies { 3 }
    active { true }
    complete { true }

    factory :complete_item, aliases: %i[inactive_item] do
      directory { 'B135491460_C106083325' }
      title { 'Cultural atlas of Ancient Egypt' }
      author { 'Baines, John, 1946-' }
      publisher { 'New York : Checkmark Books, c2000.' }
      physical_desc { '240 p. : ill. (some col.), col. maps ; 31 cm.' }
      copies { 0 }
      active { false }
      complete { true }
    end

    factory :incomplete_item, aliases: %i[incomplete_no_directory] do
      directory { 'b155001346_C044219363' }
      title { 'Villette' }
      author { 'Brontë, Charlotte' }
      publisher { "New York : St. Martin's Press, c1992." }
      physical_desc { 'ix, 171 p. ; c23 cm.' }
      copies { 0 }
      active { false }
      complete { false }
    end

    factory :incomplete_no_images do
      directory { 'b18357550_C106160623' }
      title { 'Herakleides : a portrait mummy from Roman Egypt' }
      publisher { 'Los Angeles : J. Paul Getty Museum, c2010.' }
      physical_desc { '112 p. : ill. (some col.), col. map ; 24 cm.' }
      author { 'Corcoran, Lorelei Hilda, 1953-' }
      copies { 2 }
      active { true }
      complete { false }
    end

    factory :incomplete_no_manifest do
      directory { 'b23752729_C118406204' }
      title { 'Art of Mesopotamia' }
      publisher { 'New York, New York : Thames & Hudson Inc.' }
      physical_desc { '376 pages : illustrations (chiefly color) ; 28 cm' }
      author { 'Bahrani, Zainab' }
      complete { false }
    end

    factory :incomplete_no_marc do
      directory { 'b135297126_BT 7 064 812' }
      title { 'The great depression in Europe, 1929-1939' }
      author { 'Clavin, Patricia.' }
      publisher { "New York : St. Martin's Press, 2000." }
      physical_desc { 'viii, 244 p. : ill. ; 23 cm.' }
      complete { false }
    end

    factory :incomplete_marc_only do
      directory { 'b11996535_B 3 106 704' }
      title { 'Pamphlet' }
      author { 'Canada. Department of Agriculture.' }
      publisher { 'Ottawa, 1922-1935.' }
      physical_desc { '168 v. ill. 20-25 cm.' }
      complete { false }
    end
  end
end

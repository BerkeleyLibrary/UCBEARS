# Patron dumps

This directory contains response bodies for queries to the Millennium
patron dump API used by `Patron::Record.find()`; e.g.
[`99999997.txt`](99999997.txt) for

```
GET https://dev-oskicatp.berkeley.edu:54620/PATRONAPI/99999997/dump
```

The file [`patron_helper.rb`](../../patron_helper.rb) contains a helper
function, `stub_patron_dump(patron_id)`, which uses WebMock to stub a request for
a particular patron ID to return the corresponding file. For example,
in an RSpec test:

```ruby
describe 'patron attributes' do
  it 'reads patron 99999997' do
    stub_patron_dump('99999997')
    patron = Patron::Record.find('99999997')
    expect(patron.faculty?).to eq(false)
    expect(patron.student?).to eq(true)
    expect(patron.type).to eq(Patron::Type::UNDERGRAD)
  end
end
```

Also see `patron_helper.rb` for a map from patron types to patron numbers.

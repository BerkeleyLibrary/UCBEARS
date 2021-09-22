# 1.3.1 (next)

- changed `LendingItemLoan` `active` scope and `active?` method to only include 
  loans on active items
- fixed issue where successfully checking out the last copy of an item would show
  an "item unavailable" message
- fixed issue where returning an expired loan, or a loan for an inactive item,
  would show potentially confusing error messages
- `meta http-equiv="Refresh"` on view page now just redirects to the view itself
  (allowing the loan to expire) rather than explicitly returning the item

# 1.3.0 (2021-09-21)

User-facing changes:

- update to Mirador 3
  - remove [`mirador_rails` Ruby gem](https://github.com/sul-dlss/mirador_rails) in favor of
  [`mirador` JavaScript package](https://github.com/ProjectMirador/mirador)
- update to 2019 UC Berkeley Library design standards and UCB brand guidelines
  - remove [Bootsrap](https://github.com/twbs/bootstrap) in favor of custom CSS
- fix issue where completed loans would sometimes produce spurious error messages,
  or cause availability to be calculated incorrectly

Technical changes:

- add `/health` endpoint for monitoring
- update to Rails 6.1n
  - use Webpacker for JavaScript assets (Sprockets is still used for CSS/SCSS)
  - remove `bootstrap`, `jquery-rails`, and `jquery-ui-rails` Ruby gems
- fix IIPImage configuration in CI
  - use [`iipsrv`](https://github.com/BerkeleyLibrary/iipsrv) instead of
    [`iiip-nginx-single`](https://git.lib.berkeley.edu/lap/iiip-nginx-single)
    (note that while `docker-compose.yml` still depends on an internal
    Berkeley image, it can be built from the GitHub
    [`iipsrv`](https://github.com/BerkeleyLibrary/iipsrv) repo)
  - add `iipsrv` service to [Jenkinsfile](Jenkinsfile)
  - move test data to `iipsrv-data` for interoperability with `iipsrv` Jenkins
    pipeline
  - make sure WebMock properly intercepts requests, at least outside of 
    Capybara testing (see [webmock#955](https://github.com/bblimke/webmock/issues/955))

# 1.2.0 (2021-09-10)

- improves stats display
- adds CSV downloads for all loans or for loans by date
- limits stats page checkout information to last 7 days
- allows use of full browser width on landscape screens
- properly distinguishes expired loans from returned loans
- replaces explicit loan status in database with status calculated from
  loan date, due date, and return date

# 1.1.0 (2021-08-31)

- Item directory names are now validated to ensure they don't start or end with
  whitespace, or contain non-printing characters
- Items with no author (e.g. complete journal issues) can now be activated
- Publisher and physical description are now cached in the database along with
  author and title, instead of read from `marc.xml` every time they're needed
- Edit page improvements:
  - Author, title, publisher, and physical description can now be edited
  - Author, title, publisher, and physical description can now be reloaded on
    demand from `marc.xml`
- IIIF manifest uses the database title and author, if different from those
  in the manifest template

# 1.0.0 (2021-08-25)

First production release. Changes since 0.1.0:

## Ruby version

Reverted to Ruby 2.7.2 to deal with an apparent permissions issue that would
prevent the application from running on certain versions of Docker.

## Anonymized checkouts / reading history

Patron UIDs are no longer stored in loan records in the database;
instead patrons are assigned a “borrower ID” (a [randomly generated
UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier#Version_4_(random)))
on first login. This borrower ID is only used in loan records, and cannot
be associated with the patron UID.

This borrower ID is encrypted along with the UID as a “borrower token”,
which is never stored in the database, but is stored in a session cookie,
and also appended to the item URL the patron sees after checkout.

A patron can thus access their checkout **either** by:

1. accessing their individual, tokenized view URL from any browser or
   device, or
2. accessing the general view URL “direct link” for the item from a browser
   that has the token in a session cookie.

In either case a CAS login is required, and if the user's CalNet UID does
not match the UID encrypted into the token, the token is ignored as
invalid.

Note that we’re not scrubbing UIDs or borrower tokens from log records, so
with access to the logs it would still be possible to reconstruct patron
reading history, so this system is far from ideal, but given we only retain
logs for 90 days it at least mitigates the risk to patron privacy somewhat.

## Statistics

### Statistics page

A basic statistics page is available to administrators, providing some
information such as the number of unique users of different types, number
of items, number of loans for each item, total number of loans, and median
loan duration.

### User statistics and patron privacy

In order to allow counting unique users, we do store UIDs in a
`SessionCounter` table, along with a counter incremented each time the user
logs into the application. However, there is no record of when the user
logged in, or when the table was updated, which should make it more
difficult to associate UIDs with lending activity.

# 0.1.0 (2021-08-23)

Initial GitHub release.

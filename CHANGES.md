# 1.7.2 (2022-04-26)

Functional:

- Adds checkbox to set/unset the default term for new items.

# 1.7.1 (2022-04-22)

Functional:

- Adds `AFFILIATE-TYPE-VISITING STU RESEARCHER` to the list of student affiliations.

Technical:

- Host for CAS logout URL now uses `$CAS_HOST` environment variable if set, instead of
  being hard-coded to `auth.berkeley.edu` or `auth-test.berkeley.edu`.
- `omniauth-cas` updated to released 2.0 version.

Development:

- Adds `rubocop-rails` and `rubocop-rspec` style checks, w/related code cleanup.

# 1.7.0 (2022-03-07)

Usability / accessibility improvements:

- Adds an alt-media notice to the checkout page, directing students with print disabilities
  to the previously existing PDF service.
- Page images are now identified as "Image <number>" rather than "Page <number>" to reduce
  confusion between physical and logical pages.
- "Index" sidebar is removed to reduce confusion.
- "Information" sidebar is now labeled "Transcript".

Technical:

- Dockerfile is now based on Debian Slim rather than Alpine.
- Updated from Ruby 3.0.2 to Ruby 3.0.3.
- Most text strings are now in `locales/en.yml` for ease of customization / editing.
- IIIF manifests are now stored as plain JSON (with placeholder URLs) rather than
  as an ERB template.
  - Note that this slightly changes the format of the `/processing` API endpoing, insofar
    as it now returns `has_manifest` rather than `has_manifest_template`
- Webpacker/JavaScript changes:
  - Tests now use the JavaScript packs from `public/packs` instead of a separate
    `packs/test`.
  - `rails check` no longer calls `assets:precompile`; running tests requires compiling
    assets separately. (This was already the case in practice due to Webpacker usually
    failing to properly detect changes.)
  - `rails js:eslint` no longer calls `yarn:install`; checking JavaScript style requires
    separately running `yarn:install`, `webpacker:compile`, or `assets:precompile`.
  - ESLint is now included in "production" JS dependencies to facilitate running style
    checks against a production image in CI.
  

# 1.6.0 (2022-02-14)

New features:

- renames "Administration" to "Manage Items"
- adds a "Manage Terms" administration tab, allowing creating, editing, and deleting terms
- removes legacy "Index (old)" item administration interface

Technical updates:

- adds a `/processing` API endpoint returning information on processing
  directories in JSON format, e.g.

  ```json
  [
    { 
      "directory":"991085919326206532_C122741395",
      "mtime":"2022-02-11T03:49:10.266+00:00",
      "path":"/ucbears/processing/991085919326206532_C122741395",
      "exists":true,
      "complete":false,
      "has_page_images":false,
      "has_marc_record":false,
      "has_manifest_template":false
    },
    {
      "directory":"991085915425906532_C117801326",
      "mtime":"2022-02-11T03:12:12.846+00:00",
      "path":"/ucbears/processing/991085915425906532_C117801326",
      "exists":true,
      "complete":false,
      "has_page_images":true,
      "has_marc_record":false,
      "has_manifest_template":false
    }
  ]
  ```

- failed JSON requests now return errors in a consistent format, e.g.:

  ```json
  {
    "success": false,
    "error": {
      "code": 403,
      "message": "Forbidden",
      "errors": [
        { "location":  "/terms.json" }
      ]
    }
  }
  ```

  or

  ```json
  {
    "success":false,
    "error":{
      "code":422,
      "errors":[
        {
          "type":"greater_than_or_equal_to",
          "attribute":"copies",
          "message":"Copies must be greater than or equal to 0",
          "details":{
            "error":"greater_than_or_equal_to",
            "value":-1,
            "count":0
          }
        },
        {
          "type":"Active items must have at least one copy.",
          "attribute":"base",
          "message":"Active items must have at least one copy.",
          "details":{
            "error":"Active items must have at least one copy."
          }
        }
      ]
    }
  }
  ```
- unauthenticated requests to API endpoints now return an error
  response instead of a 302 redirect to the login page
- fixes an issue where administrative UI components could be 
  constructed (though not rendered) even on error pages
- default (root) route is now to `session#index`, which requires
  a login, redirects administrators to "Manage Items", and displays
  403 Forbidden to non-administrators

# 1.5.2 (2022-01-18)

- fixes an issue where paging in the admin item list could be 
  incorrect when selecting multiple terms
- fixes an issue where multiple requests could trigger scanning 
  for new items simultaneously, resulting in failed attempts to 
  create duplicate records

# 1.5.1 (2022-01-07)

- admin page now includes an item count
- fixes an issue where the delete button on the admin page was not
  enabled/disabled correctly
- fixes an issue where the delete button on the admin page was not
  actually deleting items

# 1.5 (2022-01-07)

New features:

- default admin home page is a new item administration interface with
  sorting, filtering, pagination, and in-line editing
- items are now assigned to terms, and only available for checkout during
  assigned term dates
  - default terms are Berkeley's Fall 2021 and Spring 2022
  - existing items are assigned by default to Fall 2021
  - specified items are also assigned to Spring 2022

Technical updates:

- item completeness is now cached in the database to simplify searching
  and filtering
- Ruby version updated to 3.0.2
- `Gemfile.lock` now specifies both `x86_64` and `arm64` and both
  `linux-musl` (Alpine Linux) and `darwin` (macOS)

# 1.3.1 (2021-09-30)

Admin:

- item list now has a maximum width of 1000px
- buttons are rearranged and colors adjusted to better highlight the primary action
- index page now includes a list of in-process item directories, with a warning for any
  older than a configured limit (currently 1 hour, although 10 minutes would probably be
  enough to indicate a problem)

Viewer:

- Mirador window is now sized dynamically to the viewport vertical size.
- sidebar now only displays the OCR transcript (other metadata is concealed with CSS `display: none`)
- navigation area is at the upper right of the canvas instead of the lower center, and should
  not overlap page images
- mouse wheel scroll events in the canvas are properly intercepted to prevent mouse zoom and 
  allow the browser window to scroll
- "scroll" view is disabled pro tem till we figure out vertical scrolling
- Mirador brand icon and Project Mirador link now displayed in lower left corner

Checkouts and returns:

- changed `LendingItemLoan` `active` scope and `active?` method to only include 
  loans on active items
- fixed issue where successfully checking out the last copy of an item would show
  an "item unavailable" message
- fixed issue where returning an expired loan, or a loan for an inactive item,
  would show potentially confusing error messages
- `meta http-equiv="Refresh"` on view page now just redirects to the view itself
  (allowing the loan to expire) rather than explicitly returning the item

Miscellaneous:

- accessibility "skip link" now displays properly when pressing tab on page load
- main document area margins and padding are adjusted to match header and footer
- footer margins and font sizes are adjusted to better match Berkeley style
- links now take on the same highlight colors for tab navigation focus as for mouse hover
- responsive "hamburger menu" should now be highlighted properly via tab navigation
- "danger" color is slightly darker to improve contrast

# 1.3.0 (2021-09-21)

User-facing changes:

- update to Mirador 3
  - remove [`mirador_rails` Ruby gem](https://github.com/sul-dlss/mirador_rails) in favor of
  [`mirador` JavaScript package](https://github.com/ProjectMirador/mirador)
- update to 2019 UC Berkeley Library design standards and UCB brand guidelines
  (color, typography, etc.)
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

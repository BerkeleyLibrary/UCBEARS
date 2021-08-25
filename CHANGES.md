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

# Docs - JustMatch API

Developer guide for JustMatch Api.

* [High level components](#high-level-components)
* [Database](#database)

## High level components

The code follows most Rails conventions. If you've worked with Rails before the project should be easy to navigate.

* __Technology__
  - Ruby 2.4
  - Ruby on Rails 5.1
  - PostgreSQL 9.5
  - Redis 3

* __PostgreSQL extensions__
  + `unaccent`

* __Environment variables__
  + Used to configure app
  + [List of variables](environment-variables.md)


* __Uses `sidekiq` for background jobs (including emails)__


* __All role based access is contained in `app/policies`__
  - One for each controller
  - Uses the `pundit` gem


* __JSON serialization__
  - Uses the `active_model_serializers` gem
    + Uses the JSON API adapter
  - Uses the `jsonapi_helpers` gem
  - Follows the JSON API standard


* __Notifications and emails__
  - An `ActionMailer` like implementation for SMS has been implemented, see `JobTexter`
  - Every single notification/email has their on class in `app/notifiers`
    + Notifiers invokes the appropriate mailers and texters
  - Sends SMS messages using Twilio and the `twilio-ruby` gem

* __Invoices__
  - Integrates with Frilans Finans, using the gem `frilans_finans_api`
  - Almost all API communication with Frilans Finans is done from scheduled jobs

* __Geocoding__
  - Uses `geocoder`
  - All models that need geocoding abilities include the `Geocodable` module
  - Uses Google Maps under-the-hood


* __File upload__
  - Uses the `paperclip` gem, together with `aws-sdk` to save files to AWS S3
  - All files are uploaded separately, the API then returns a token, that then can be used when creating a new resource


* __Internal gems__
  - Some logic have been extracted to gems located in `lib/`, i.e
    + `JsonApiHelpers` "A set of helpers for generating JSON API compliant responses."
    + `FrilansFinansApi` "Interact with Frilans Finans API."
  - They aren't published separately because they aren't quite complete or ready for external use


* __Errors & Monitoring__
  - Uses the Airbrake and the `airbrake` gem for error notifications


* __API versions__
  - All routes namespaced under `api/v1/`
  - All controllers namespaced `Api::V1`


* __Admin tools__
  - Uses `activeadmin` gem
  - Admin interface under `admin` subdomain
  - Admin insights interface under path `/insights`
    + Uses the `blazer` gem


* __SQL queries/finders__
  - Located in `app/models/queries` namespaced under `Queries`


* __Documentation__
  - Generate docs with `script/docs`
  - Uses the `apipie-rails` gem
  - API documentation is annotated just above each controller method
  - The `Doxxer` class in `app/support` is for writing and reading API response examples


* __Tests__
  - Uses `rspec`
  - Uses `factory_girl`
  - Runners in `spec/spec_support/runners` are used to run extra checks when running tests
    + Runs only when running the entire test suite or if explicitly set
    + Some of them can halt the execution and return a non-zero exit status.
  - Test helpers are located in `spec/spec_support`
  - Uses `webmock`
  - Geocode mocks in `spec/spec_support/geocoder_support.rb`

* __Model translation__
  - Each model that need translated columns
    + has a corresponding model, i.e `JobTranslation`
    + includes `Translatable` module
  - Translation model
    + includes `TranslationModel` module
  - Defines the translated columns with the `translates` macro
    + That macro defines an instance method `set_translation` on the model
  - There are a few helper services, and corresponding `ActiveJob` classes to process translations
    + `ProcessTranslationService` takes a translation and creates translations for to all eligible locales
    + `CreateTranslationService` takes a translation and a language for it to be translated to
    + Both `ProcessTranslationService` and `CreateTranslationService` have corresponding background jobs `ProcessTranslationJob` and `CreateTranslationJob`
  - Uses Google Translate under the hood
  - Translations will only be created if the detected source language is over a certain threshold

* __Static Translations__
  - Uses `rails-i18n`
  - Stored in `config/locales/`
  - Supports fallbacks
  - Uses [Transifex](https://www.transifex.com/justarrived/justmatch-api/) to translate.
    + Configuration in `.tx/config`
    + Push/pull translations with [Transifex CLI](http://docs.transifex.com/client/)

* __Receiving SMS__
  - Configure a HTTP POST Hook in the Twilio Console
    + Add the route: `POST https://api.justarrived.se/api/v1/sms/receive?ja_KEY=$JA_KEY`, replace `$JA_KEY` with something secret.
  - The SMS from number will be looked up and if there is a match a message will be added to the chat between that user and our "support user" or admin.

* __Receiving Email__
  - The env variable `DEFAULT_SUPPORT_EMAIL` should match the email of the "support user"
  - See Sendgrids docs https://sendgrid.com/docs/API_Reference/Webhooks/parse.html
  - Basically you need to
    1. Setup some CNAME records pointing to Sendgrids
    2. Setup and MX record for a subdomain that Sendgrid will "handle", i.e if you setup `email.example.com`, Sendgrid will handle all emails sent to that subdomain
    3. Configure their "Parse" HTTP POST Hook
    4. Add the route: `POST https://api.justarrived.se/api/v1/email/receive?ja_KEY=$JA_KEY`, replace `$JA_KEY` with something secret.
  - The email from address will be looked up and if there is a match a message will be added to the chat between that user and our "support user" or admin.


## Database

__Setup dev database from Heroku app__

```
$ bin/rails dev:db:heroku_import[heroku-app-name]
```

if you're using `zsh` you have to escape `[` and `]`, [more info](https://robots.thoughtbot.com/how-to-use-arguments-in-a-rake-task).

```
$ bin/rails dev:db:heroku_import\[heroku-app-name\]
```

__Restore database command__

```
$ pg_restore --no-owner -d <db_name> <path_to_db_data_dump>
```

__Setup database from Heroku for development use__

Download database dump from Heroku
```
$ heroku pg:backups:download --app=<heroku_application_name>
```

Import database to development database
```
# Reset the database to make sure the database dump is imported cleanly
$ rails db:drop db:create
$ pg_restore --no-owner -d just_match_development latest.dump
```

Anonymize database

```
$ rails dev:anonymize_database
```

The database is now safe for development use and you can login as admin with username `admin@example.com` and password `12345678`.

# business_atomic_events gem

## Purpose
This gem contains code for sending hourly updates on certain key tables to our AWS based Open Search cluster

## Usage

### Gemfile
```
gem 'business_atomic_events', git: 'git@github.com:eLocal/business_atomic_events.git
gem 'flipper'
```

You may also want to constrain usage of the gem to production environment only.

### Application Code
#### Open Search Credentials
Add `config/initializers/business_atomic_events.rb` file containing the following code to make sure
your application has access to the credentials required to communicate with Open Search:
```
# frozen_string_literal: true

if Rails.env.production?
  require 'ssm_to_env'
  SsmToEnv.load!(
    '/service/business_atomic_events/open_search/production/password' => 'OPEN_SEARCH_PASSWORD',
    '/service/business_atomic_events/open_search/production/user_name' => 'OPEN_SEARCH_USER'
  )
end
```

#### Configuration
1. Ensure existence of Open Search indices that will receive data fed by this gem. Please refer to https://aws.amazon.com/opensearch-service/getting-started/ for details. Our existing Open Search cluster is here: https://search-john-test-duj2npqk5k27ffd2uwgb52rm7i.us-east-1.es.amazonaws.com`. Index names should start with index prefixes which need to be the same for all indices of an application. For our major applications. Open search index name's structure is `<index_prefix>_<index>`, where both `index_prefix` and `index` are reflected in the YAML configuration file described below in (2).
2. Create a configuration file `config/business_atomic_events.yml` which will define queries to populate Open Search indices (one query per index) and specify a target index for each query. A good example is the affiliates application's configuration file you can find here: `https://github.com/eLocal/affiliates/blob/master/config/business_atomic_events.yml`.
3. Ensure that a periodic (cron-based) job named `BusinessAtomicEvents::FeedGenerator` runs a few minutes past each hour.

## Flipper Configuration
Flipper gem is a required dependency. 
1. Feature `bae_current_feeds` needs to be enabled for current hourly feeds generation.
2. Two or more features are required to be enabled for generation of historic feeds. One of them is `bae_history_feeds`. Additionally, for each index that needs historic feeds generation, enable a feature named `bae_history_<index-name>`. E.g, if an index in `business_atomic_events.yml` configuration file is listed as `outbound_call_pings`, then the feature to enable is `bae_history_outbound_call_pings`.

## Invoking Historic Feeds Generation
While current feeds will be generated automatically via `BusinessAtomicEvents::FeedGenerator` cron-based job , historic feeds need to be triggered manually.  Log into one of the production servers via ssh and start rails console from the application directory via `bin/rails c` command.  Then, at the console prompt, start the historic feeds job for the required date interval, e.g.: 
```
BusinessAtomicEvents::SpawnHistoricFeeds.perform_async('2022-01-01', '2022-10-19')
```

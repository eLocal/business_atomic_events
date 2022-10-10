# business_atomic_events gem

## Purpose
This gem contains code for sending hourly updates on certain key tables to our AWS based Open Search cluster

## Usage

### Gemfile
gem 'business_atomic_events', git: 'git@github.com:eLocal/business_atomic_events.git'

You may also want to constrain usage of the gem to production environment only

### Application Code
#### Open Search Credentials
Add a file config/initializers/business_atomic_events.rb containing the following code to make sure
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
1. Ensure existence of Open Search indices that will receive data fed by this gem. Please refer to https://aws.amazon.com/opensearch-service/getting-started/ for details.
2. Create a configuration file config/business_atomic_events.yml which will define queries to populate Open Search indices (one query per index) and specify a target index for each query. A good example is the affiliates application's configuration file you can find here: https://github.com/eLocal/affiliates/blob/master/config/business_atomic_events.yml
3. Ensure that a periodic (cron-based) job named `BusinessAtomicEvents::FeedGenerator` runs a few minutes past each hour.

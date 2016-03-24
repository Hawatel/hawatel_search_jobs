[![Build Status](https://travis-ci.org/Hawatel/hawatel_search_jobs.svg?branch=master)](https://travis-ci.org/Hawatel/hawatel_search_jobs)
[![Code Climate](https://codeclimate.com/github/Hawatel/hawatel_search_jobs/badges/gpa.svg)](https://codeclimate.com/github/Hawatel/hawatel_search_jobs)
[![Inline docs](http://inch-ci.org/github/Hawatel/hawatel_search_jobs.svg?branch=master)](http://inch-ci.org/github/Hawatel/hawatel_search_jobs)
[![Gem Version](https://badge.fury.io/rb/hawatel_search_jobs.svg)](https://badge.fury.io/rb/hawatel_search_jobs)
[![Dependency Status](https://gemnasium.com/Hawatel/hawatel_search_jobs.svg)](https://gemnasium.com/Hawatel/hawatel_search_jobs)

# Hawatel Search Jobs

Hawatel_search_jobs, it is gem which provides ease access to API from popular job websites to get current job offers. At this moment, supported backends are indeed.com, careerjet.com, xing.com, careerbuilder.com and reed.co.uk.

Before you can start using the gem, you need have an accounts/tokens for each portal where is required by API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hawatel_search_jobs'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hawatel_search_jobs

## Usage

#### How to configure access to search engine APIs
```ruby
HawatelSearchJobs.configure do |config|
  config.indeed[:activated] = true
  config.indeed[:api]       = 'api.indeed.com'
  config.indeed[:version]   = '2'
  config.indeed[:publisher] = 'secret-key'

  config.xing[:activated]           = true
  config.xing[:consumer_key]        = 'secret-key'
  config.xing[:consumer_secret]     = 'secret-key'
  config.xing[:oauth_token]         = 'secret-key'
  config.xing[:oauth_token_secret]  = 'secret-key'

  config.reed[:activated] = true
  config.reed[:api]       = 'reed.co.uk/api'
  config.reed[:clientid]  = 'secret-key'
  config.reed[:version]   = '1.0'

  config.careerbuilder[:activated]  = true
  config.careerbuilder[:api]        = 'api.careerbuilder.com'
  config.careerbuilder[:clientid]   = 'secret-key'
  config.careerbuilder[:version]    = 'v2'

  config.careerjet[:activated]   = true
  config.careerjet[:api]         = 'public.api.careerjet.net'
end
```

#### Where to get a secret-key
 1. Indeed: http://www.indeed.com/jsp/apiinfo.jsp
 2. Xing: https://dev.xing.com
 3. Reed: https://www.reed.co.uk/developers/jobseeker
 4. Careerbuilder: http://developer.careerbuilder.com
 5. Careerjet: secret-key is no needed (http://www.careerjet.com/partners/api/)

#### Get first page of job offers
There are two ways to read the returned job offers.

+ Returned job offers by search_jobs method:
```ruby
  client = HawatelSearchJobs::Client.new
  result = client.search_jobs({:keywords => 'ruby'})
    p result[:indeed]
    p result[:xing]
    p result[:reed]
    p result[:careerbuilder]
    p result[:careerjet]
```

+ Access to the instance variable jobs_table.
Instance variable *jobs_table* always has last returned job offers.
```ruby
  client = HawatelSearchJobs::Client.new
  client.search_jobs({:keywords => 'ruby'})
  p client.jobs_table
```

Each API has a limit of returned records. For consistency, each API returns maximum `25` records.

#### Get next page of job offers
```ruby
  client = HawatelSearchJobs::Client.new
  client.search_jobs({:keywords => 'ruby'})
  p client.next
```

#### Get all pages of job offers
```ruby
  client = HawatelSearchJobs::Client.new
  client.search_jobs({:keywords => 'ruby'})
  
  job_offers = Array.new
  
  while(client.next) do
    job_offers << client.jobs_table
  end
```
If keywords will be too general probably each API will return loads of data and then a daily limit for an API provider can be exceeded.
Reed about your daily limit for each API on the provider side.

#### How many job offers were found
```ruby
  client = HawatelSearchJobs::Client.new
  client.search_jobs({:keywords => 'ruby'})
  p client.count # for all APIs
  p client.count('indeed') # for a particular API
```
The `client.count` returns count of total results for each APIs which can be returned to you if you use `client.next` method.

## Structure of job offers table
Below is an example for indeed but each API has the same result structure.
```ruby
  client = HawatelSearchJobs::Client.new
  client.search_jobs({:keywords => 'ruby'})
  result = client.jobs_table
  
  result[:indeed][:code]            # HTTP status code (see https://en.wikipedia.org/wiki/List_of_HTTP_status_codes)
  result[:indeed][:message]         # HTTP message (seee https://en.wikipedia.org/wiki/List_of_HTTP_status_codes)
  
  result[:indeed][:totalResults]    # Total results of job offers which matches to your search criteria on API provider
  result[:indeed][:page]            # Current results page number counted from index 0
  result[:indeed][:last]            # Last results page number
  result[:indeed][:key]             # Internal key which usuely keep last URL sent to API or last used keywords
  
  result[:indeed][:jobs]            # OpenStruct array which store returned job offers from API provider
  result[:indeed][:jobs].jobtitle   # Job title
  result[:indeed][:jobs].location   # Job location
  result[:indeed][:jobs].company    # Company name which posted the job
  result[:indeed][:jobs].date       # Date of the posted job (format %d/%m/%y)
  result[:indeed][:jobs].url        # Source URL to the job offer
```

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md)


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


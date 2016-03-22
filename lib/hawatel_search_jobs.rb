##
# = Hawatel Search Jobs
# More details how to use it was described here {HawatelSearchJobs::Client}
module HawatelSearchJobs
  require 'hawatel_search_jobs/helpers'
  require 'hawatel_search_jobs/api'
  require 'hawatel_search_jobs/client'

  class << self
    attr_accessor :indeed, :xing, :reed, :careerbuilder, :careerjet

    ##
    # How to configure APIs go to example {HawatelSearchJobs::Client#search_jobs}
    def configure
      @indeed         = default_indeed(Hash.new)
      @xing           = default_xing(Hash.new)
      @reed           = default_reed(Hash.new)
      @careerbuilder  = default_careerbuilder(Hash.new)
      @careerjet      = default_careerjet(Hash.new)
      yield self
      true
    end

    private

    def default_xing(settings)
      settings[:activated]          = false
      settings[:consumer_key]       = ''
      settings[:consumer_secret]    = ''
      settings[:oauth_token]        = ''
      settings[:oauth_token_secret] = ''
      return settings
    end

    def default_indeed(settings)
      settings[:activated]  = false
      settings[:api]        = 'api.indeed.com'
      settings[:version]    = '2'
      settings[:publisher]  = ''
      return settings
    end

    def default_careerjet(settings)
      settings[:activated]  = false
      settings[:api]        = 'public.api.careerjet.net'
      return settings
    end

    def default_reed(settings)
      settings[:activated]  = false
      settings[:api]        = 'reed.co.uk/api'
      settings[:version]    = '1.0'
      return settings
    end

    def default_careerbuilder(settings)
      settings[:activated]  = false
      settings[:api]        = 'api.careerbuilder.com'
      settings[:version]    = 'v2'
      return settings
    end
  end

end

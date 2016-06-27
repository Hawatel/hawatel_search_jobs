module HawatelSearchJobs
  ##
  # = Client for a jobs search engine
  #
  # @!attribute [rw] indeed
  #   @return [Hash] settings of API
  # @!attribute [rw] xing
  #   @return [Hash] settings of API
  # @!attribute [rw] reed
  #   @return [Hash] settings of API
  # @!attribute [rw] careerbuilder
  #   @return [Hash] settings of API
  # @!attribute [rw] careerjet
  #   @return [Hash] settings of API
  class Client
    include HawatelSearchJobs::Api

    # Values have to be the same name like module name of usesd APIs (HawatelSearchJobs::Api::[ApiName])
    APIS = ['Indeed', 'Xing', 'Reed', 'Careerbuilder', 'CareerJet']

    attr_reader :jobs_table

    DEFAULT = {
        :keywords => '',
        :location => '',
        :company  => '',
    }

    def initialize
      APIS.each do |api|
        metaclasses.send(:attr_reader, api.downcase.to_sym)
        instance_variable_set("@#{api.downcase}", HawatelSearchJobs.instance_variable_get("@"+api.downcase))
      end
    end

    def metaclasses
      class << self; self; end
    end

    # Search Jobs by specific criteria
    # @param query [Hash]
    # @option query [String] :keywords
    # @option query [String] :location not working in Xing API
    # @option query [String] :company not working in Reed API
    # @example
    #       HawatelSearchJobs.configure do |config|
    #           config.indeed[:activated] = true
    #           config.indeed[:api]       = 'api.indeed.com'
    #           config.indeed[:version]   = '2'
    #           config.indeed[:publisher] = 'secret-key'
    #           config.indeed[:page_size] = 25 # allowed range <1,25>
    #
    #           config.xing[:activated]           = true
    #           config.xing[:consumer_key]        = 'secret-key'
    #           config.xing[:consumer_secret]     = 'secret-key'
    #           config.xing[:oauth_token]         = 'secret-key'
    #           config.xing[:oauth_token_secret]  = 'secret-key'
    #           config.xing[:page_size]           = 25 # allowed range <1,100>
    #
    #           config.reed[:activated] = true
    #           config.reed[:api]       = 'reed.co.uk/api'
    #           config.reed[:clientid]  = 'secret-key'
    #           config.reed[:version]   = '1.0'
    #           config.reed[:page_size] = 25 # allowed range <1,100>
    #
    #           config.careerbuilder[:activated]  = true
    #           config.careerbuilder[:api]        = 'api.careerbuilder.com'
    #           config.careerbuilder[:clientid]   = 'secret-key'
    #           config.careerbuilder[:version]    = 'v2'
    #           config.careerbuilder[:page_size]  = 25 # allowed range <1,100>
    #
    #           config.careerjet[:activated]   = true
    #           config.careerjet[:api]         = 'public.api.careerjet.net'
    #           config.careerjet[:page_size]   = 25 # allowed range <1,99>
    #         end
    #
    #       client = HawatelSearchJobs::Client.new
    #       client.search_jobs({:keywords => 'ruby'})
    #
    #       p client.jobs_table[:indeed]
    #       p client.jobs_table[:xing]
    #       p client.jobs_table[:reed]
    #       p client.jobs_table[:careerbuilder]
    #       p client.jobs_table[:careerjet]
    #
    #       client.next
    # @return [Hash] First page of result for all providers (default maximum 25 records for each page)
    def search_jobs(query = {})
      query = DEFAULT.merge(query)

      @jobs_table = Hash.new

      APIS.each do |api|
        api_module_name = Object.const_get('HawatelSearchJobs').const_get('Api').const_get(api)
        api_inst_var = instance_variable_get("@"+api.downcase)
        @jobs_table[api.downcase.to_sym] = api_module_name.search({:settings => api_inst_var, :query => query}) if api_inst_var[:activated]
      end

      @jobs_table
    end

    # Get next page of result
    # @example
    #   p client.next
    #   p client.jobs_table
    # @return [Hash] Next page of result for all providers (default maximum 25 records for each)
    def next
      next_result = Hash.new
      APIS.each do |api|
        api_module_name = Object.const_get('HawatelSearchJobs').const_get('Api').const_get(api)
        api_inst_var = instance_variable_get("@"+api.downcase)
        api_sym_name = api.downcase.to_sym

        if api_inst_var[:activated] && next_result?(api_sym_name)
          next_result[api_sym_name] = api_module_name.page({:settings => api_inst_var,
                                                            :page => @jobs_table[api_sym_name].page + 1,
                                                            :query_key => @jobs_table[api_sym_name].key})
        end
      end

      return nil if next_result.empty?

      @jobs_table = next_result
    end


    # Sum jobs offers from specified api or count all
    #
    # @param args [Hash]
    # @option args [String] :api name
    # @example
    #   p client.count
    #   p client.count('indeed')
    #
    # @return [Integer]
    def count(api = nil)
      sum = 0

      if api
        api = api.downcase
        api_inst_var = instance_variable_get("@"+api)
        if api_inst_var[:activated]
          sum = @jobs_table[:"#{api}"].totalResults if @jobs_table[:"#{api}"].totalResults
        end
      else
        APIS.each do |provider|
          api_inst_var = instance_variable_get("@"+provider.downcase)
          if api_inst_var[:activated]
            provider = provider.downcase
            sum += @jobs_table[:"#{provider}"].totalResults if @jobs_table[:"#{provider}"].totalResults
          end
        end
      end
      return sum
    end

    private
    def next_result?(provider)
      if @jobs_table[provider] && @jobs_table[provider].page && @jobs_table[provider].last &&
          @jobs_table[provider].page < @jobs_table[provider].last
        true
      else
        false
      end

    end

  end
end


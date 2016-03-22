module HawatelSearchJobs
  module Api
    module CareerJet
      class << self
        include HawatelSearchJobs::Helpers::Base

        DEFAULT = {
            :keywords => '',
            :location => '',
            :company  => ''
        }

        # Search jobs based on specified keywords or location
        #
        # @param args [Hash]
        # @option args :query [Hash] search criteria
        #   - *:keywords*​ (String) - keywords for search
        # @option args [Integer] :page page number (default value 0)
        # @option args [String] :query_key option provided by page() method
        #
        # @example
        #   search(:settings => HawatelSearchJobs.careerjet,:query => {:keywords => 'ruby'})
        #   search(:query_key => 'http://api.../search?locale_code=US_en&sort=date&keywords=ruby', :page => 0)
        #
        # @return [Hash<OpenStruct>]
        def search(args)
          args[:query] = DEFAULT.merge(args[:query]) if args[:query]
          args[:page]  = 0 if args[:page].nil?

          if args[:query_key].to_s.empty?
            url_request = build_url(args)
          else
            url_request = args[:query_key]
          end

          if url_request
            attributes = Hash.new
            response   = send_request(url_request)
            result     = JSON(response.body)
            if response.code == '200' && result['type'] == 'ERROR'
              attributes[:code] = 501
              attributes[:msg]  = result['error']
              return OpenStruct.new(attributes)
            else
              attributes[:code] = response.code
              attributes[:msg]  = response.message
              return OpenStruct.new(attributes) if response.code != '200'
            end
            attributes[:totalResults] = result['hits']
            attributes[:page] = args[:page]
            attributes[:last] = result['pages'] - 1
            attributes[:key]  = url_request
            attributes[:jobs] = parse_raw_data(result)
            OpenStruct.new(attributes)
          else
            OpenStruct.new({:code => 501, :msg => 'lack of keywords or api setting'})
          end
        end

        # Show next page of results
        #
        # @param args [Hash]
        # @option args [Integer] :page specified page number (default 0)
        # @option args [String] :query_key full url from last query
        #
        # @example
        #   page({:query_key => result.key, :page => 2}
        #
        # @return [Hash<OpenStrunct>]
        def page(args)
          args[:page] = 0 if args[:page].nil?
          args[:query_key] = args[:query_key].gsub(/&page=.*/, '') << "&page=#{args[:page]+1}"
          return search(args)
        end

        private

        # Build query URL
        #
        # @param args [Hash]
        # @option args query [Hash] - search criteria
        #   - *:keywords* (String) - keywords for search
        #   - *:location* (String) - specified location for search criteria (default: europe)
        # @option settings [Hash]
        #   - *:api* (String) - api ip or domainname
        #
        # @example
        #   build_url(:query => {:keywords => 'ruby'}, :settings => {:api => 'http://api...'} }
        #
        # @return [String] ready to call URL
        def build_url(args)
          keywords = args[:query][:keywords] if !args[:query][:keywords].to_s.empty?
          api_url  = args[:settings][:api]   if !args[:settings][:api].to_s.empty?
          if keywords && api_url
            !args[:query][:location].to_s.empty? ? location = args[:query][:location] : location = 'europe'
            "http://#{api_url}/search?locale_code=US_en&pagesize=25&sort=date&keywords=#{keywords}&location=#{location}&page=1"
          end
        end


        # Build jobs array with specified attributes
        #
        # @param result [Hash]
        # @option result [Hash] :jobs jobs hash array return from API
        #
        # @return [Array<OpenStruct>]
        def parse_raw_data(result)
          jobs = Array.new
          return jobs if result['jobs'].to_s.empty?
          result['jobs'].each do |offer|
            job = Hash.new
            job[:jobtitle] = offer['title']
            job[:location] = offer['locations']
            job[:company]  = offer['company']
            job[:date]     = convert_date_to_format(offer['date'],'%d/%m/%y')
            job[:url]      = offer['url']
            job = convert_empty_to_nil(job)
            jobs << OpenStruct.new(job)
          end
          return jobs
        end

      end
    end
  end
end

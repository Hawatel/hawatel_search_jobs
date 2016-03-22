require 'ostruct'
require 'net/http'
require 'json'

module HawatelSearchJobs
  module Api
    module Indeed
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
        # @option args [String] :query_key full url from last query, option deliverd by page() method
        # @option args :query [Hash] search criteria
        #   - *:keywords* (String) keywords for search
        #   - *:location* (String) specified location for search criteria (default all countries)
        # @option args :settings [Hash]
        #   - *:api* (String) hostname or ip address api server
        #   - *:publisher* (String) authentication string
        #
        # @example
        #   search(:settings => HawatelSearchJobs.indeed,:query => {:keywords => 'ruby'})
        #   search(:query_key => 'http://api.../ads/apisearch?publisher=12323&q=ruby')
        #
        # @return [Hash<OpenStruct>]
        def search(args)
          args[:query] = DEFAULT.merge(args[:query]) if args[:query]
          if args[:query_key].to_s.empty?
            url_request = build_url(args)
          else
            url_request = args[:query_key]
          end

          if url_request
            attributes  = Hash.new
            response   = send_request(url_request)
            result     = JSON(response.body)
            if response.code == '200' && result['error']
              attributes[:code] = 501
              attributes[:msg]  = result['error']
              return OpenStruct.new(attributes)
            else
              attributes[:code] = response.code
              attributes[:msg]  = response.message
              return OpenStruct.new(attributes) if response.code != '200'
            end
            attributes[:totalResults] = result['totalResults']
            attributes[:page] = result['pageNumber']
            #attributes[:last] = (result['totalResults'] / 25) - 1
            attributes[:last] = paging_info(25, result['totalResults'])
            attributes[:key]  = url_request
            attributes[:jobs] = parse_raw_data(result)
            OpenStruct.new(attributes)
          else
            OpenStruct.new({:code => 501, :msg => 'lack of api or publisher setting'})
          end
        end

        # Show next page of results
        #
        # @param args [Hash]
        # @option args [Integer] :page  page number (default 0)
        # @option args [String] :query_key url from last query
        #
        # @example
        #   page({:query_key => result.key, :page => 2}
        #
        # @return [Hash<OpenStruct>]
        def page(args)
          args[:page] = 0 if args[:page].nil?
          if args[:query_key]
            url = args[:query_key].gsub(/&start=.*/, '') << "&start=#{args[:page]*25}"
            search({:query_key => url})
          end
        end

      private
        # Build query URL
        #
        # @param args [Hash]
        # option args :query [Hash]
        #   - *:keywords* (String) keywords for search
        #   - *:location* (String) search jobs from specified location
        #   - *:salary* (String) show only position above specified salary
        #   - *:company* (String) find position from specified company
        # @option args :settings [Hash]
        #   - *:api* (String) hostname or ip address api server
        #   - *:publisher* (String) authentication string
        #
        # @example
        #   build_url(:query => {:keywords => 'ruby'}, :settings => {:api => 'http://api...',:publisher => '23234'}}
        #
        # @return [String]
        def build_url(args)
          api_url   = args[:settings][:api]
          publisher = args[:settings][:publisher]
          location  = args[:query][:location]
          salary    = args[:query][:salary]
          company   = args[:query][:company]
          keywords  = args[:query][:keywords]

          if !keywords.to_s.empty? && !company.to_s.empty?
            keywords  = "company:#{company}+#{keywords}"
          elsif keywords.to_s.empty? && !company.to_s.empty?
            keywords  = "company:#{company}"
          end
          if api_url && publisher
            "http://#{api_url}/ads/apisearch?publisher=#{publisher}&q=#{keywords}&salary=#{salary}&l=#{location}"\
            "&v=2&format=json&limit=25&start=0"
          end
        end

        # Build jobs array with specified attributes
        #
        # @param result [Hash]
        # @option result [Hash] :results job attributes
        #
        # @return [Array<OpenStruct>]
        def parse_raw_data(result)
          jobs = Array.new
          return jobs if result['results'].to_s.empty?
          result['results'].each do |offer|
            job = Hash.new
            job[:jobtitle] = offer['jobtitle'] if offer['jobtitle']
            job[:location] = "#{offer['country']}, #{offer['city']}"
            job[:company]  = offer['company']
            job[:date]     = convert_date_to_format(offer['date'],'%d/%m/%y')
            job[:url]      = offer['url']
            job = convert_empty_to_nil(job)
            jobs << OpenStruct.new(job)
          end
          return jobs
        end

        def paging_info(limit, total_result)
          return nil if total_result == 0

          mod = total_result.to_i % limit.to_i
          if mod == 0
            last = (total_result.to_i / limit.to_i) - 1
          else
            last = (total_result.to_i / limit.to_i).to_i
          end

          last
        end

      end
    end
  end
end
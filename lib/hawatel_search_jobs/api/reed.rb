require 'ostruct'

module HawatelSearchJobs
  module Api
    ##
    # = Reed.co.uk API
    #
    # @see https://www.reed.co.uk/developers/Jobseeker
    module Reed
      class << self
        include HawatelSearchJobs::Helpers::Base

        DEFAULT = {
            :keywords => '',
            :location => '',
        }

        RESULT_LIMIT = 25

        # Search jobs by specific criteria
        # @param [Hash] args
        # @option args :settings [Hash] search criteria
        #   - *:api* (String) - URL API (default: reed.co.uk/api)
        #   - *:version* (String) - a version of API (default: 1.0)
        #   - *:clientid* (String) - API Key (see https://www.reed.co.uk/developers/Jobseeker)
        # @option args :query [Hash] settings of API
        #   - *:keywors* (String)
        #   - *:location* (String)
        # @example
        #   jobs = Reed.search({:settings => {
        #                                   :api => 'reed.co.uk/api',
        #                                   :version => '1.0',
        #                                   :clientid => 'secret-code'},
        #                                :query => {
        #                                   :keywords => 'ruby',
        #                                   :location => 'London'})
        # @return [Hash] First page of the result (see constant RESULT_LIMIT)
        def search(args)
          args[:query] = DEFAULT.merge(args[:query]) if args[:query]
          args[:page_size] = args[:settings][:page_size].to_s.empty? ? RESULT_LIMIT : args[:settings][:page_size].to_i
          args[:page_size] = RESULT_LIMIT if args[:page_size] <= 0 || args[:page_size] > 100

          if args[:query_key].nil?
            url_request = prepare_conn_string(args) + prepare_query(args)
          else
            url_request = args[:query_key]
          end

          response = api_request(url_request, args[:settings][:clientid])
          attributes = build_jobs_table(response, url_request, args[:page_size])
          OpenStruct.new(attributes)
        end

        # Get a specific page result
        # At the beging you have to run {search} method and get :key from result and pass it to the argument :query_key
        # @param [Hash] args
        # @option args :settings [Hash] see {search}
        # @option args [Integer] :page page number counted from 0
        # @option args [String] :query_key
        # @example
        #   jobs = Careerbuilder.page({:settings => {
        #                                   :api => 'api.careerbuilder.com',
        #                                   :version => 'v2',
        #                                   :clientid => 'secret-code'},
        #                              :page => 5,
        #                              :query_key => 'value from :key returned by search method'})
        # @return [Hash] Job offers from specific page
        def page(args)
          page = args[:page].to_i || 0
          page_size = args[:settings][:page_size].to_s.empty? ? RESULT_LIMIT : args[:settings][:page_size].to_i
          page_size = RESULT_LIMIT if page_size <= 0 || page_size > 100

          if args[:query_key]
            #limit = result_limit(args[:query_key])
            url_request = args[:query_key].gsub(/&resultsToSkip=\d+/, '') << "&resultsToSkip=#{page * page_size}"
            args[:query_key] = url_request
            search(args)
          end
        end

        private

        def build_jobs_table(response, url_request, page_size)
          attributes  = Hash.new
          attributes[:code] = response.code.to_i
          attributes[:msg]  = response.message

          attributes[:totalResults] = 0
          attributes[:page] = nil
          attributes[:last] = nil
          attributes[:key]  = url_request
          attributes[:jobs] = nil


          if response.code.to_i == 200
            json_response = JSON.parse(response.body)
            begin
              if !json_response['results'].to_s.empty?
                attributes[:totalResults] = json_response['totalResults'] || 0

                page_info = paging_info(url_request, attributes[:totalResults], page_size)
                attributes[:page] = page_info.page
                attributes[:last] = page_info.last

                attributes[:key]  = url_request
                attributes[:jobs] = parse_raw_data(json_response)
              end
            rescue
              raise "Something wrong with returned data: #{json_response}"
            end
          end
          attributes
        end

        def api_request(url, clientid = nil)
          opt = Hash.new

          if clientid
            opt = { :basic_auth => {
                :username => clientid,
                :password => ''
            }}
          end

          send_request(url, opt)
        end

        def prepare_query(args)
          "keywords=#{args[:query][:keywords]}&locationName=#{args[:query][:location]}"
        end

        def prepare_conn_string(args)
          conn_string = "https://#{args[:settings][:api]}/#{args[:settings][:version]}/search?resultsToTake=#{args[:page_size]}&"
          conn_string
        end

        def parse_raw_data(data)
          jobs = Array.new
          data['results'].each do |offer|
            job = Hash.new
            job[:jobtitle] = offer['jobTitle'] if offer['jobTitle']
            job[:location] = "United Kingdom, #{offer['locationName']}"
            job[:company]  = offer['employerName']
            job[:date]     = convert_date_to_format(offer['date'],'%d/%m/%y')
            job[:url]      = offer['jobUrl']

            job = convert_empty_to_nil(job)

            jobs << OpenStruct.new(job)
          end
          jobs
        rescue
          raise "Cannot parse raw data: #{data}"
        end

        # def result_limit(url)
        #   result = url.match(/\resultsToTake=(\d+)/)
        #   result ? result[1].to_i : RESULT_LIMIT
        # end

        def result_skip(url)
          result = url.match(/\&resultsToSkip=(\d+)/)
          result ? result[1].to_i : 0
        end

        def paging_info(url, total_result, page_size)
          return OpenStruct.new({:page => nil, :last => nil}) if total_result == 0

          result_skip = result_skip(url)

          if result_skip == 0 && total_result > 0
            page = 0
          else
            page = (result_skip / page_size).to_i
          end

          mod = total_result.to_i % page_size.to_i
          if mod == 0
            last = (total_result.to_i / page_size.to_i) - 1
          else
            last = (total_result.to_i / page_size.to_i).to_i
          end

          OpenStruct.new({:page => page, :last => last})
        end

      end
    end
  end
end
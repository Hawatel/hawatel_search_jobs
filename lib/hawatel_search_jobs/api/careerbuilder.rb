require 'ostruct'
require 'active_support/core_ext/hash'

module HawatelSearchJobs
  module Api
    ##
    # = Carerrbuilder API
    #
    # @see 	http://api.careerbuilder.com/Search/jobsearch/jobsearchinfo.aspx
    module Careerbuilder
      class << self
        include HawatelSearchJobs::Helpers::Base

        DEFAULT = {
            :keywords => '',
            :location => '',
            :company  => ''
        }

        RESULT_LIMIT = 25

        # Search jobs by specific criteria
        # @param [Hash] args
        # @option args :settings [Hash] search criteria
        #   - *:api* (String) - URL API (default: api.careerbuilder.com)
        #   - *:version* (String) - a version of API (default: v2)
        #   - *:clientid* (String) - Private Developer Key (see http://developer.careerbuilder.com)
        # @option args :query [Hash] settings of API
        #   - *:keywors* (String)
        #   - *:location* (String)
        #   - *:company* (String)
        # @example
        #   jobs = Careerbuilder.search({:settings => {
        #                                   :api => 'api.careerbuilder.com',
        #                                   :version => 'v2',
        #                                   :clientid => 'secret-code'},
        #                                :query => {
        #                                   :keywords => 'ruby',
        #                                   :location => 'London',
        #                                   :company => ''}})
        # @return [Hash] First page of the result (see constant RESULT_LIMIT)
        def search(args)
          args[:query] = DEFAULT.merge(args[:query]) if args[:query]

          if args[:query_key].nil?
            url_request = prepare_conn_string(args) + prepare_query(args)
          else
            url_request = args[:query_key]
          end

          response = send_request(url_request)
          attributes = build_jobs_table(response, url_request)
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
          if args[:query_key]
            url_request = args[:query_key].gsub(/&PageNumber=\d+/, '') << "&PageNumber=#{page+1}"
            args[:query_key] = url_request
            search(args)
          end
        end

        private

        def build_jobs_table(response, url_request)
          attributes  = Hash.new
          attributes[:code] = response.code.to_i
          attributes[:msg]  = response.message

          attributes[:totalResults] = 0
          attributes[:page] = nil
          attributes[:last] = nil
          attributes[:key]  = url_request
          attributes[:jobs] = nil

          if response.code.to_i == 200
            xml_response = Hash.from_xml(response.body.gsub('\n', ''))
            begin
              if xml_response['ResponseJobSearch'] && xml_response['ResponseJobSearch']['Results']
                attributes[:totalResults] = xml_response['ResponseJobSearch']['TotalCount'].to_i || 0
                attributes[:page] = get_page_number(url_request) - 1
                attributes[:last] = xml_response['ResponseJobSearch']['TotalPages'].to_i - 1
                attributes[:key]  = url_request
                attributes[:jobs] = parse_raw_data(xml_response)
              end
            rescue
              raise "Something wrong with returned data: #{xml_response}"
            end
          end
          attributes
        end

        def prepare_query(args)
          "Keywords=#{args[:query][:keywords]}&" \
          "Location=#{args[:query][:location]}&" \
          "CompanyName=#{args[:query][:company]}"
        end

        def prepare_conn_string(args)
          conn_string = "https://#{args[:settings][:api]}/#{args[:settings][:version]}/jobsearch?" \
          "PerPage=#{RESULT_LIMIT}&DeveloperKey=#{args[:settings][:clientid]}&"

          conn_string
        end

        def parse_raw_data(data)
          jobs = Array.new
          data['ResponseJobSearch']['Results']['JobSearchResult'].each do |offer|
            job = Hash.new
            job[:jobtitle] = offer['JobTitle'] if offer['JobTitle']

            country = get_country_name(offer['State'], data['ResponseJobSearch']['SearchMetaData']['SearchLocations'])
            location = country
            location += ", #{offer['City']}" if offer['City'] && country != offer['City']
            job[:location] = location
            job[:company]  = offer['Company']

            newdate = offer['PostedDate'].split('/')
            job[:date]  = "#{newdate[1]}/#{newdate[0]}/#{newdate[2]}"

            job[:date]     = convert_date_to_format(job[:date],'%d/%m/%y')
            job[:url]      = offer['JobDetailsURL']

            job = convert_empty_to_nil(job)

            jobs << OpenStruct.new(job)
          end
          jobs
        rescue
          raise "Cannot parse raw data - #{data.inspect}"
        end

        def get_country_name(code, locations)
          locations.each do |loc|
            if loc[1]['StateCode'] && code && code.to_s == loc[1]['StateCode'].to_s
              return loc[1]['City'] if loc[1]['City']
            end
          end

          'United States'
        rescue
          raise "Cannot get country name (code=#{code}, locations=#{locations}"
        end

        def get_page_number(url)
          result = url.match(/\&PageNumber=(\d+)/)
          result ? result[1].to_i : 1
        end

      end
    end
  end
end
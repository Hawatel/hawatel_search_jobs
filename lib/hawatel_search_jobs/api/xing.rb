require 'xing_api'

module HawatelSearchJobs::Api
  module Xing
    class << self
      include HawatelSearchJobs::Helpers::Base

      DEFAULT = {
          :keywords => '',
          :location => '',
          :company  => ''
      }

      RESULT_LIMIT = 25

      # @see https://github.com/xing/xing_api
      # Search jobs based on specified keywords
      #
      # @param args [Hash]
      # @option args :query [Hash] search criteria
      #   - *:keywords* (String )
      # @option args :setting [Hash] @see https://dev.xing.com/docs/authentication
      #   - *:consumer_key* (String) - consumer key, required for authentication
      #   - *:consumer_secret* (String) - consumer secret, required for authentication
      #   - *:oauth_token* (String) - outh toker, required for authentication
      #   - *:oauth_token_secret* (String) - outh token secret, required for authentication
      #
      # @example
      #   search(:settings => HawatelSearchJobs.xing,:query => {:keywords => 'ruby'})
      #
      # @return [Hash<OpenStruct>]
      def search(args)
        args[:query] = DEFAULT.merge(args[:query]) if args[:query]
        keywords = args[:query][:keywords]
        page_size = args[:settings][:page_size].to_s.empty? ? RESULT_LIMIT : args[:settings][:page_size].to_i
        page_size = RESULT_LIMIT if page_size <= 0 || page_size > 100

        result = send_request({:keywords => keywords, :offset => 0, :settings => args[:settings], :page_size => page_size})

        if !result[:code]
          set_attributes({:result => result, :page => 0, :keywords => keywords, :page_size => page_size})
        else
          OpenStruct.new({:code => 501, :msg => 'incorrect settings'})
        end
      end

      # Show next page of results
      #
      # @param args [Hash]
      # @option page [Integer] page numer (default 0)
      # @option query_key [String] keywords from last query
      #
      # @example
      #   page({:query_key => result.key, :page => 2}
      #
      # @return [Hash<OpenStruct>]
      def page(args)
        args[:page] = 0 if args[:page].nil?
        page_size = args[:settings][:page_size].to_s.empty? ? RESULT_LIMIT : args[:settings][:page_size].to_i
        page_size = RESULT_LIMIT if page_size <= 0 || page_size > 100

        result = XingApi::Job.search(args[:query_key], {:limit => page_size, :offset => args[:page]*page_size})
        set_attributes({:result => result, :page => args[:page], :keywords => args[:query_key], :page_size => page_size})
      rescue XingApi::Error => e
        {:code => e.status_code, :msg => e.text}
      end

      private
      # Call Xing client request
      #
      # @param args [Hash]
      # @option settings [Hash] authentication attributes
      # @option keywords [String] keywords for query
      #
      # @return [Hash<OpenStruct>]
      def send_request(args)
        set_settings(args[:settings])

        XingApi::Job.search(args[:keywords], {:limit => args[:page_size], :offset => 0})
      rescue XingApi::Error => e
        {:code => e.status_code, :msg => e.text}
      end

      # Build final result - set required attributes and return openstruct object
      #
      def set_attributes(args)
        attributes = Hash.new
        attributes[:totalResults] = args[:result][:jobs][:total]
        attributes[:code]  = '200'
        attributes[:msg]   = "OK"
        attributes[:page]  = args[:page]
        attributes[:last]  = args[:result][:jobs][:total] / args[:page_size]
        attributes[:key]   = args[:keywords]
        attributes[:jobs]  = parse_raw_data(args[:result])
        OpenStruct.new(attributes)
      end

      # Build jobs array with specified attributes
      #
      # @return [Array<OpenStruct>]
      def parse_raw_data(result)
        jobs = Array.new
        return jobs if result[:jobs].to_s.empty?
        result[:jobs][:items].each do |offer|
          job = Hash.new
          job[:jobtitle] = offer[:title]
          job[:location] = "#{offer[:location][:country]}, #{offer[:location][:city]}"
          job[:company]  = offer[:company][:name]
          job[:date]     = convert_date_to_format(offer[:published_at], '%d/%m/%y')
          job[:url]      = offer[:links][:xing]
          job = convert_empty_to_nil(job)
          jobs << OpenStruct.new(job)
        end
        return jobs
      end

      # Set settings for XingApi client
      #
      # @param args [Hash]
      def set_settings(args)
        XingApi::Client.configure do |config|
          config.consumer_key = args[:consumer_key]
          config.consumer_secret = args[:consumer_secret]
          config.oauth_token = args[:oauth_token]
          config.oauth_token_secret = args[:oauth_token_secret]
        end
      end

    end
  end
end

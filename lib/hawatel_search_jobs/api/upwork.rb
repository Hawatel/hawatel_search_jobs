require 'upwork/api'
require 'upwork/api/routers/jobs/search'

module HawatelSearchJobs::Api
  module Upwork
    class << self
      include HawatelSearchJobs::Helpers::Base

      DEFAULT = {
          :keywords => '',
          :location => '',
          :company  => ''
      }

      RESULT_LIMIT = 25

      # @see https://github.com/upwork/ruby-upwork
      # Search jobs based on specified keywords
      #
      # @param args [Hash]
      # @option args :query [Hash] search criteria
      #   - *:keywords* (String )
      # @option args :setting [Hash] @see https://developers.upwork.com/?lang=python#authentication_oauth-10
      #   - *:consumer_key* (String) - consumer key, required for authentication
      #   - *:consumer_secret* (String) - consumer secret, required for authentication
      #
      # @example
      #   search(:settings => HawatelSearchJobs.upwork,:query => {:keywords => 'ruby'})
      #
      # @return [Hash<OpenStruct>]
      def search(args)
        args[:query] = DEFAULT.merge(args[:query]) if args[:query]
        keywords = args[:query][:keywords]
        page_size = args[:settings][:page_size].to_s.empty? ? RESULT_LIMIT : args[:settings][:page_size].to_i
        page_size = RESULT_LIMIT if page_size <= 0 || page_size > 100

        result = send_request({:keywords => keywords, :offset => 0, :settings => args[:settings], :page_size => page_size})

        if result['error']
          error_handling(result)
        else
          set_attributes({:result => result, :page => 0, :keywords => keywords, :page_size => page_size})
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

        result = send_request({:keywords => args[:query_key], :offset => args[:page]*page_size, :settings => args[:settings], :page_size => page_size})

        if result['error']
          error_handling(result)
        else
          set_attributes({:result => result, :page => args[:page], :keywords => args[:query_key], :page_size => page_size})
        end
      end

      private
      # Call Upwork client request
      #
      # @param args [Hash]
      # @option settings [Hash] authentication attributes
      # @option keywords [String] keywords for query
      #
      # @return [Hash<OpenStruct>]
      def send_request(args)
        @client = ::Upwork::Api::Client.new(set_settings(args[:settings])) if @client.nil?
        @jobs_client = ::Upwork::Api::Routers::Jobs::Search.new(@client) if @jobs_client.nil?

        @jobs_client.find({'q' => args[:keywords], 'sort' => 'create_time desc', 'paging' => "#{args[:offset]};#{args[:page_size]}"})
      rescue => e
        {:code => "500", :msg => "Internal error #{e}" }
      end

      # Build final result - set required attributes and return openstruct object
      #
      def set_attributes(args)
        total = args[:result]['paging']['total'] ? args[:result]['paging']['total'].to_i : 0
        # "paging"=>{"offset"=>0, "count"=>100, "total"=>886}
        attributes = Hash.new
        attributes[:totalResults] = total
        attributes[:code]  = '200'
        attributes[:msg]   = "OK"
        attributes[:page]  = args[:page]
        attributes[:last]  = total / args[:page_size]
        attributes[:key]   = args[:keywords]
        attributes[:jobs]  = parse_raw_data(args[:result])
        OpenStruct.new(attributes)
      end

      # Build jobs array with specified attributes
      # @note Format of response:
      #   {"server_time"=>1468313522, "auth_user"=>{"first_name"=>"xyz", "last_name"=>"xyz", "timezone"=>"Europe/Prague", "timezone_offset"=>"7200"},
      #   "profile_access"=>"public,odesk", "jobs"=>[{"id"=>"~01dde83fce38b65f90", "title"=>"Node.js & Ruby on Rails developer needed", "snippet"=>"The app is build in RoR,
      #   for chat we use Node.js and WebRTC for video\n\n1. Deploy to Digital Ocean with SSL", "category2"=>"Web, Mobile & Software Dev", "subcategory2"=>"Web Development",
      #   "skills"=>["node.js", "redis", "ruby-on-rails"], "job_type"=>"Hourly", "budget"=>0, "duration"=>"Less than 1 week", "workload"=>"10-30 hrs/week",
      #   "job_status"=>"Open", "date_created"=>"2016-06-30T15:14:03+0000", "url"=>"http://www.upwork.com/jobs/~01dde83fce38b65f90", "client"=>{"country"=>"Ireland", "feedback"=>5,
      #   "reviews_count"=>16, "jobs_posted"=>62, "past_hires"=>53, "payment_verification_status"=>"VERIFIED"}}], paging"=>{"offset"=>0, "count"=>100, "total"=>886}
      # @return [Array<OpenStruct>]
      def parse_raw_data(result)
        jobs = Array.new
        return jobs if result['jobs'].to_s.empty?
        result['jobs'].each do |offer|
          job = Hash.new
          job[:jobtitle] = offer['title']
          job[:location] = (offer['client'] && offer['client']['country']) ? offer['client']['country'] : nil
          job[:company]  = 'Upwork'
          job[:date]     = convert_date_to_format(offer['date_created'], '%d/%m/%y')
          job[:url]      = offer['url']
          job = convert_empty_to_nil(job)
          jobs << OpenStruct.new(job)
        end
        return jobs
      end

      # Set settings for UpworkApi client
      #
      # @param args [Hash]
      def set_settings(args)
        ::Upwork::Api::Config.new({
          'consumer_key'    => args[:consumer_key],
          'consumer_secret' => args[:consumer_secret],
          'access_token'     => args[:oauth_token],
          'access_secret' => args[:oauth_token_secret]
        })
      end

      def error_handling(result)
        if result['error']['status'] && result['error']['message']
          OpenStruct.new({:code => result['error']['status'].to_i, :msg => result['error']['message']})
        else
          OpenStruct.new({:code => 501, :msg => 'incorrect settings'})
        end
      end

    end
  end
end

require 'net/http'
require 'json'
require 'date'

module HawatelSearchJobs
  module Helpers
    module Base

      private
      def send_request(url, opt = {})
        uri = URI.parse(url)
        req = Net::HTTP::Get.new(uri)
        if opt[:basic_auth] && opt[:basic_auth][:username] && opt[:basic_auth][:password]
          req.basic_auth(opt[:basic_auth][:username], opt[:basic_auth][:password])
        end
        sock = Net::HTTP.new(uri.host, uri.port)
        sock.use_ssl = true if uri.scheme == 'https'
        
        sock.start { |http| http.request(req) }
      end

      def convert_empty_to_nil(hash)
        new = {}
        hash.each do |k,v|
          if v.to_s.empty?
            new[k] = nil
          else
            new[k] = v
          end
        end
        new
      end

      def convert_date_to_format(date, format)
        DateTime.parse(date).to_date.strftime(format) if !date.to_s.empty?
      end
    end
  end
end
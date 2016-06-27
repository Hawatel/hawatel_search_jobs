require 'spec_helper'
require 'time'

xdescribe HawatelSearchJobs::Api::Careerbuilder do
  before(:each) do
    HawatelSearchJobs.configure do |config|
      config.careerbuilder[:api]      = 'api.careerbuilder.com'
      config.careerbuilder[:version]  = 'v2'
      config.careerbuilder[:clientid] = ''
      config.careerbuilder[:page_size]= 100
    end
  end

  context 'APIs returned jobs' do
    before(:each) do
      @query_api = {:keywords => 'ruby', :location => ''}
      @result = HawatelSearchJobs::Api::Careerbuilder.search(
          :settings => HawatelSearchJobs.careerbuilder,
          :query => {
              :keywords => @query_api[:keywords],
              :location => @query_api[:location]
          })
    end

    it '#search' do
      validate_result(@result, @query_api)
      expect(@result.page).to be >= 0
      expect(@result.last).to be >= 0
    end

    it '#results ordered by date descending' do
      validate_result(@result, @query_api)

      last_date = nil
      @result.jobs.each do |job|
        if !job.date.to_s.empty?
          if !last_date.nil?
            expect(convert_date_to_timestamp(job.date)).to be <= last_date
          end
          last_date = convert_date_to_timestamp(job.date)
        end
      end
    end

    it '#page' do
      validate_result(@result, @query_api)

      page_result =
          HawatelSearchJobs::Api::Careerbuilder.page({
                                                     :settings => HawatelSearchJobs.careerbuilder,
                                                     :query_key => @result.key,
                                                     :page => 1})
      expect(page_result.key).to match(/&PageNumber=2/)
      expect(page_result.page).to be == 1
      expect(page_result.last).to be >= 0
    end

    it '#count of jobs is the same like page_size' do
      validate_result(@result, @query_api)
      expect(@result.jobs.count).to eq(HawatelSearchJobs.careerbuilder[:page_size])
    end

    it '#next page does not contain last page' do
      validate_result(@result, @query_api)

      first_page =
          HawatelSearchJobs::Api::Careerbuilder.page({
                                                     :settings => HawatelSearchJobs.careerbuilder,
                                                     :query_key => @result.key,
                                                     :page => 1})
      expect(first_page.key).to match(/&PageNumber=2/)
      expect(first_page.page).to be == 1
      expect(first_page.last).to be >= 0

      second_page =
          HawatelSearchJobs::Api::Careerbuilder.page({
                                                      :settings => HawatelSearchJobs.careerbuilder,
                                                      :query_key => @result.key,
                                                      :page => 2})

      expect(second_page.key).to match(/&PageNumber=3/)
      expect(second_page.page).to be == 2
      expect(second_page.last).to be >= 0

      first_page.jobs.each do |first_job|
        second_page.jobs.each do |second_job|
          expect(first_job.url).not_to eq(second_job.url)
        end
      end

    end
  end

  context 'APIs returned empty table' do
    before(:each) do
      @query_api = {:keywords => 'job-not-found-zero-records', :location => 'London'}
      @result = HawatelSearchJobs::Api::Careerbuilder.search(
          :settings => HawatelSearchJobs.careerbuilder,
          :query => {
              :keywords => @query_api[:keywords],
              :location => @query_api[:location]
          })
    end

    it '#search' do
      validate_result(@result, @query_api)
      expect(@result.totalResults).to eq(0)
      expect(@result.page).to be_nil
      expect(@result.last).to be_nil
      expect(@result.jobs).to be_nil
    end

    it '#page' do
      validate_result(@result, @query_api)
      page_result =
          HawatelSearchJobs::Api::Careerbuilder.page({
                                                     :settings => HawatelSearchJobs.careerbuilder,
                                                     :query_key => @result.key,
                                                     :page => 1})
      expect(page_result.key).to match(/&PageNumber=2/)
      expect(@result.totalResults).to eq(0)
      expect(@result.page).to be_nil
      expect(@result.last).to be_nil
      expect(@result.jobs).to be_nil
    end
  end

  private

  def validate_result(result, query_api)
    expect(result.code).to eq(200)
    expect(result.msg).to eq('OK')
    expect(result.totalResults).to be >= 0
    expect(result.key).to match("Location=#{query_api[:location]}")
    expect(result.key).to match("Keywords=#{query_api[:keywords]}")
  end

  def convert_date_to_timestamp(job_date)
    date = job_date.split('/')
    return Time.parse("#{date[2]}-#{date[1]}-#{date[0]}").to_i
  end

end
require 'spec_helper'

xdescribe HawatelSearchJobs::Api::Careerbuilder do
  before(:each) do
    HawatelSearchJobs.configure do |config|
      config.careerbuilder[:api]      = 'api.careerbuilder.com'
      config.careerbuilder[:version]  = 'v2'
      config.careerbuilder[:clientid] = ''
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

    it '#page' do
      validate_result(@result, @query_api)
      page_result = HawatelSearchJobs::Api::Careerbuilder.page({
                                                                   :settings => HawatelSearchJobs.careerbuilder,
                                                                   :query_key => @result.key,
                                                                   :page => 1})
      expect(page_result.key).to match(/&PageNumber=2/)
      expect(page_result.page).to be == 1
      expect(page_result.last).to be >= 0
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
      page_result = HawatelSearchJobs::Api::Careerbuilder.page({
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
end
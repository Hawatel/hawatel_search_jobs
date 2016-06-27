require 'spec_helper'
require 'xing_api'

xdescribe "HawatelSearchJobs::Api::Xing"  do

  before(:each) do
    HawatelSearchJobs.configure do |config|
      config.xing[:consumer_key]       = ''
      config.xing[:consumer_secret]    = ''
      config.xing[:oauth_token]        = ''
      config.xing[:oauth_token_secret] = ''
      config.xing[:page_size]          = 100
    end
  end

  let(:client) { return HawatelSearchJobs::Client.new }
  let(:result) {
    return HawatelSearchJobs::Api::Xing.search(
      :settings => HawatelSearchJobs.xing,
      :query    => { :keywords => 'ruby', :company => '' }
  )}

  it "metadata from search() result" do
    expect(result.page).to be_a_kind_of(Integer)
    expect(result.last).to be_a_kind_of(Integer)
    expect(result.totalResults).to be_a_kind_of(Integer)
  end

  it "job attributes from search() result" do
    result.jobs.each do |job|
      expect(job.jobtitle).to be_a_kind_of(String)
      expect(job.location).to be_a_kind_of(String)
      expect(job.company).to be_a_kind_of(String)
      expect(job.url).to include('http')
    end
  end

  it "count of jobs is the same like page_size" do
    expect(result.jobs.count).to eq(HawatelSearchJobs.xing[:page_size])
  end

  it "call page() without specified page (default 0)" do
    jobs = HawatelSearchJobs::Api::Xing.page({:settings => HawatelSearchJobs.xing, :query_key => result.key})
    expect(jobs.page).to eq(0)
  end

  it "call page() with specified page" do
    jobs = HawatelSearchJobs::Api::Xing.page({:settings => HawatelSearchJobs.xing, :query_key => result.key, :page => 1})
    expect(jobs.page).to eq(1)
  end

  it "next page does not contain last page" do
    jobs_first = HawatelSearchJobs::Api::Xing.page({:settings => HawatelSearchJobs.xing, :query_key => result.key, :page => 1})
    expect(jobs_first.page).to eq(1)

    jobs_second = HawatelSearchJobs::Api::Xing.page({:settings => HawatelSearchJobs.xing, :query_key => result.key, :page => 2})
    expect(jobs_second.page).to eq(2)

    jobs_first.jobs.each do |first_job|
      jobs_second.jobs.each do |second_job|
        expect(first_job.url).not_to eq(second_job.url)
      end
    end

  end

end
require 'spec_helper'
require 'xing_api'

describe "HawatelSearchJobs::Api::Xing"  do

  before(:each) do
    HawatelSearchJobs.configure do |config|
      config.xing[:consumer_key]       = ''
      config.xing[:consumer_secret]    = ''
      config.xing[:oauth_token]        = ''
      config.xing[:oauth_token_secret] = ''
    end
  end

  let(:client) { return HawatelSearchJobs::Client.new }
  let(:result) {
    return HawatelSearchJobs::Api::Xing.search(
      :settings => HawatelSearchJobs.xing,
      :query    => { :keywords => 'ruby', :company => '' }
  )}

  xit "metadata from search() result" do
    expect(result.page).to be_a_kind_of(Integer)
    expect(result.last).to be_a_kind_of(Integer)
    expect(result.totalResults).to be_a_kind_of(Integer)
  end

  xit "job attributes from search() result" do
    result.jobs.each do |job|
      expect(job.jobtitle).to be_a_kind_of(String)
      expect(job.location).to be_a_kind_of(String)
      expect(job.company).to be_a_kind_of(String)
      expect(job.url).to include('http')
    end
  end

  xit "call page() without specified page (default 0)" do
    jobs = HawatelSearchJobs::Api::Xing.page({:query_key => result.key})
    expect(jobs.page).to eq(0)
  end

  xit "call page() with specified page" do
    jobs = HawatelSearchJobs::Api::Xing.page({:query_key => result.key, :page => 1})
    expect(jobs.page).to eq(1)
  end


end
require 'spec_helper'

xdescribe "HawatelSearchJobs::Api::Indeed"  do

  before(:each) do
    HawatelSearchJobs.configure do |config|
      config.indeed[:api] = 'api.indeed.com'
      config.indeed[:publisher] = ''
    end
  end

  let(:client) { return HawatelSearchJobs::Client.new }
  let(:result) {
    return HawatelSearchJobs::Api::Indeed.search(
        :settings => HawatelSearchJobs.indeed,
        :query    => { :keywords => 'ruby', :company => '' }
    )}

  it "metadata from search() result" do
    expect(result.totalResults).to be_a_kind_of(Integer)
    expect(result.page).to be_a_kind_of(Integer)
    expect(result.last).to be_a_kind_of(Integer)
    expect(result.key).to include("http")
  end

  it "job attrubutes from search() result" do
    expect(result.jobs.size).to be > 0
    result.jobs.each do |job|
      expect(job.jobtitle).to be_a_kind_of(String)
      expect(job.location).to be_a_kind_of(String)
      expect(job.company).to be_a_kind_of(String)
      expect(job.url).to include('http')
    end
  end

  it "call page() without page param (default 0)" do
    jobs = HawatelSearchJobs::Api::Indeed.page({:query_key => result.key})
    expect(jobs.page).to eq(0)
  end

  it "call page() with specified page" do
    jobs = HawatelSearchJobs::Api::Indeed.page({:query_key => result.key, :page => 1})
    expect(jobs.page).to eq(1)
  end

  it "call search() with providing location param" do
    result = HawatelSearchJobs::Api::Indeed.search(:settings => HawatelSearchJobs.indeed, :query => {:location => 'US'})
    result.jobs.each do |job|
      expect(job.location).to include("US")
    end
  end

  it "call search() with providing company param" do
    result = HawatelSearchJobs::Api::Indeed.search(:settings => HawatelSearchJobs.indeed, :query => {:company => 'ibm'})
    result.jobs.each do |job|
      expect(job.company).to match(/IBM/)
    end
  end

end
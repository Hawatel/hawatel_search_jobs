require 'spec_helper'

describe HawatelSearchJobs::Api::CareerJet  do

  let(:client) { return HawatelSearchJobs::Client.new }
  let(:result) {
    return HawatelSearchJobs::Api::CareerJet.search(
          :settings => HawatelSearchJobs.careerjet,
          :query    => { :keywords => 'ruby', :company => '' }
    )
  }

  before(:each) do
    HawatelSearchJobs.configure do |config|
      config.careerjet[:api]   = 'public.api.careerjet.net'
    end
  end

  it "metadata from search() result" do
    expect(result.totalResults).to be_a_kind_of(Integer)
    expect(result.page).to be_a_kind_of(Integer)
    expect(result.last).to be_a_kind_of(Integer)
    expect(result.key).to be_a_kind_of(String)
  end

  it "job attributes from search() result" do
    expect(result.jobs.size).to be > 0
    result.jobs.each do |job|
      expect(job.jobtitle).to be_a_kind_of(String)
      expect(job.url).to include('http')
    end
  end

  it "call page() without page param (default 0)" do
    jobs =  HawatelSearchJobs::Api::CareerJet.page({:query_key => result.key})
    expect(jobs.page).to eq(0)
  end

  it "call page() with specified page" do
    jobs =  HawatelSearchJobs::Api::CareerJet.page({:query_key => result.key, :page => 2})
    expect(jobs.page).to eq(2)
  end

  it "call search() with location param" do
    result =  HawatelSearchJobs::Api::CareerJet.search(:settings => HawatelSearchJobs.careerjet,
                                                       :query => { :keywords => 'ruby', :location => 'London' })
    location_found = false
    result.jobs.each do |job|
      if job.location =~ /London/
        location_found = true
        break
      end
    end

    expect(location_found).to eq(true)
  end


end
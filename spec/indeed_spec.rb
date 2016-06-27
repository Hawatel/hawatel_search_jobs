require 'spec_helper'

xdescribe "HawatelSearchJobs::Api::Indeed"  do

  before(:each) do
    HawatelSearchJobs.configure do |config|
      config.indeed[:api] = 'api.indeed.com'
      config.indeed[:publisher] = ''
      config.indeed[:page_size] = 20
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

  it "count of jobs is the same like page_size" do
    expect(result.jobs.count).to eq(HawatelSearchJobs.indeed[:page_size])
  end

  it "call page() without page param (default 0)" do
    jobs = HawatelSearchJobs::Api::Indeed.page({:settings => HawatelSearchJobs.indeed, :query_key => result.key})
    expect(jobs.page).to eq(0)
  end

  it "call page() with specified page" do
    jobs = HawatelSearchJobs::Api::Indeed.page({:settings => HawatelSearchJobs.indeed, :query_key => result.key, :page => 1})
    expect(jobs.page).to eq(1)
  end

  it "next page does not contain last page" do
    jobs_first = HawatelSearchJobs::Api::Indeed.page({:settings => HawatelSearchJobs.indeed, :query_key => result.key, :page => 1})
    expect(jobs_first.page).to eq(1)

    jobs_second = HawatelSearchJobs::Api::Indeed.page({:settings => HawatelSearchJobs.indeed, :query_key => result.key, :page => 2})
    expect(jobs_second.page).to eq(2)

    jobs_first.jobs.each do |first_job|
      jobs_second.jobs.each do |second_job|
        expect(first_job.url).not_to eq(second_job.url)
      end
    end
  end

  it "results ordered by date descending" do
    last_date = nil
    result.jobs.each do |job|
      if !job.date.to_s.empty?
        if !last_date.nil?
          expect(convert_date_to_timestamp(job.date)).to be <= last_date
        end
        last_date = convert_date_to_timestamp(job.date)
      end
    end
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

  private

  def convert_date_to_timestamp(job_date)
    date = job_date.split('/')
    return Time.parse("#{date[2]}-#{date[1]}-#{date[0]}").to_i
  end

end
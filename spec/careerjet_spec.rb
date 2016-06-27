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
      config.careerjet[:page_size] = 99
    end
  end

  it "metadata from search() result" do
    expect(result.totalResults).to be_a_kind_of(Integer)
    expect(result.page).to be_a_kind_of(Integer)
    expect(result.last).to be_a_kind_of(Integer)
    expect(result.key).to be_a_kind_of(String)
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

  it "job attributes from search() result" do
    expect(result.jobs.size).to be > 0
    result.jobs.each do |job|
      expect(job.jobtitle).to be_a_kind_of(String)
      expect(job.url).to include('http')
    end
  end

  it "count of jobs is the same like page_size" do
    expect(result.jobs.count).to eq(HawatelSearchJobs.careerjet[:page_size])
  end

  it "call page() without page param (default 0)" do
    jobs =  HawatelSearchJobs::Api::CareerJet.page({:query_key => result.key})
    expect(jobs.page).to eq(0)
  end

  it "call page() with specified page" do
    jobs =  HawatelSearchJobs::Api::CareerJet.page({:query_key => result.key, :page => 2})
    expect(jobs.page).to eq(2)
  end

  it "next page does not contain last page" do
    jobs_first =  HawatelSearchJobs::Api::CareerJet.page({:query_key => result.key, :page => 2})
    expect(jobs_first.page).to eq(2)

    jobs_second = HawatelSearchJobs::Api::CareerJet.page({:query_key => result.key, :page => 3})
    expect(jobs_second.page).to eq(3)

    jobs_first.jobs.each do |first_job|
      jobs_second.jobs.each do |second_job|
        expect(first_job.url).not_to eq(second_job.url)
      end
    end

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

  private

  def convert_date_to_timestamp(job_date)
    date = job_date.split('/')
    return Time.parse("#{date[2]}-#{date[1]}-#{date[0]}").to_i
  end

end
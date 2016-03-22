require 'spec_helper'

describe HawatelSearchJobs::Client do
  before(:each) do
    HawatelSearchJobs.configure do |config|
      config.indeed[:activated] = true
      config.indeed[:publisher] = ''

      config.xing[:activated] = true
      config.xing[:consumer_key] = 'd'
      config.xing[:consumer_secret] = ''
      config.xing[:oauth_token] = ''
      config.xing[:oauth_token_secret] = ''

      config.reed[:activated] = true
      config.reed[:clientid] = ''

      config.careerbuilder[:activated]= true
      config.careerbuilder[:clientid] = ''

      config.careerjet[:activated]   =true
      config.careerjet[:api]   = 'public.api.careerjet.net'
    end
  end

  let(:client) { HawatelSearchJobs::Client.new }

  xit '#search valid data' do
    client.search_jobs({:keywords => 'ruby'})
    valid_jobs_table(client)
  end

  xit '#search count method' do
    client.search_jobs({:keywords => 'ruby'})
    expect(client.count).to be_kind_of(Integer)
  end

  xit '#next valid data' do
    client.search_jobs({:keywords => 'ruby'})

    valid_page_number(0, client)
    valid_jobs_table(client)
    client.next

    valid_page_number(1, client)
    valid_jobs_table(client)
  end

  private
  def valid_jobs_table(client)
    expect(client.jobs_table).not_to be_nil
    client.jobs_table.each do |provider, result|
      expect(result.totalResults).to be >= 0
    end
  end

  def valid_page_number(page, client)
    client.jobs_table.each do |provider, result|
      expect(result.page).to be == page
    end
  end
end
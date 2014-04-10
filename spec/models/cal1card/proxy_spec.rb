require 'spec_helper'

describe Cal1card::Proxy do

  let (:fake_oski_proxy) { Cal1card::Proxy.new({user_id: '61889', fake: true}) }
  let (:real_oski_proxy) { Cal1card::Proxy.new({user_id: '61889', fake: false}) }
  let (:cal1card_uri) { URI.parse(Settings.cal1card_proxy.feed_url) }

  context "fetching fake data feed" do
    subject { fake_oski_proxy.get }
    its([:body]) { should_not be_empty }
  end

  context "checking the fake feed for correct json" do
    subject { JSON.parse(fake_oski_proxy.get[:body]) }
    it {
      subject["cal1card"]["cal1cardStatus"].should == 'OK'
      subject["cal1card"]["debit"].should == '0.8'
      subject["cal1card"]["mealpoints"].should == '359.11'
      subject["cal1card"]["mealpointsPlan"].should == 'Resident Meal Plan Points'
    }
  end

  context "proper caching behaviors" do
    it "should write to cache" do
      Rails.cache.should_receive(:write)
      fake_oski_proxy.get
    end
  end

  context "getting real data feed", testext: true do
    subject { real_oski_proxy.get }
    its([:body]) { should_not be_empty }
    its([:status_code]) { should eq 200 }
  end

  context "unreachable remote server (connection errors)" do
    before(:each) {
      stub_request(:any, /.*#{cal1card_uri.hostname}.*/).to_raise(Errno::ECONNREFUSED)
      Rails.cache.should_not_receive(:write)
    }
    after(:each) { WebMock.reset! }
    subject { real_oski_proxy.get }

    its([:body]) { should eq("An unknown server error occurred") }
    its([:status_code]) { should eq(503) }
  end

  context "error on remote server (5xx errors)" do
    before(:each) {
      stub_request(:any, /.*#{cal1card_uri.hostname}.*/).to_return(status: 506)
      Rails.cache.should_not_receive(:write)
    }
    after(:each) { WebMock.reset! }
    subject { real_oski_proxy.get }

    its([:body]) { should eq("Cal1Card is currently unavailable. Please try again later.") }
    its([:status_code]) { should eq(506) }
  end
end

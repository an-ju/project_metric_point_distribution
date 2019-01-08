require "spec_helper"

RSpec.describe ProjectMetricPointDistribution do
  context 'meta data' do
    it "has a version number" do
      expect(ProjectMetricPointDistribution::VERSION).not_to be nil
    end
  end

  context 'image and score' do
    before :each do
      stub_request(:get, 'https://www.pivotaltracker.com/services/v5/projects/test/stories')
        .to_return(body: File.read('spec/data/stories.json'))
      stub_request(:get, 'https://www.pivotaltracker.com/services/v5/projects/test/memberships')
        .to_return(body: File.read('spec/data/membership.json'))
    end

    subject(:metric) do
      described_class.new(tracker_project: 'test', tracker_token: 'test token')
    end

    it 'generates the right score' do
      expect(metric.score).to eql(1.0/3.0)
    end

    it 'generates an image' do
      expect(metric.image).to have_key(:data)
    end

    it 'sets image data correctly' do
      image = metric.image
      expect(image[:data][:unstarted].length).to eql(2)
      expect(image[:data][:finished].length).to eql(1)
      expect(image[:data][:tracker_link]).not_to be_nil
    end
  end

  context 'generate test' do
    it 'generates three fake metrics' do
      expect(described_class.fake_data.length).to eql(3)
    end

    it 'generates the correct metric' do
      fake_metric = described_class.fake_data.first
      expect(fake_metric).to have_key(:image)
      expect(fake_metric).to have_key(:score)
    end

    it 'contains the correct image data' do
      fake_image = described_class.fake_data.first[:image]
      expect(fake_image[:data][:started]).not_to be_nil
      expect(fake_image[:data][:unstarted]).not_to be_nil
      expect(fake_image[:data][:planned]).not_to be_nil
      expect(fake_image[:data][:finished]).not_to be_nil
      expect(fake_image[:data][:delivered]).not_to be_nil
    end
  end

end

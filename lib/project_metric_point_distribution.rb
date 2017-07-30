require "project_metric_point_distribution/version"
require 'faraday'
require 'json'

class ProjectMetricPointDistribution
  attr_reader :raw_data

  def initialize(credentials, raw_data = nil)
    @project = credentials[:tracker_project]
    @conn = Faraday.new(url: 'https://www.pivotaltracker.com/services/v5')
    @conn.headers['Content-Type'] = 'application/json'
    @conn.headers['X-TrackerToken'] = credentials[:tracker_token]
    @raw_data = raw_data

    @max_iter = 0
    @id2name = {}
  end

  def refresh
    @image = @score = nil
    @raw_data ||= stories
  end

  def raw_data=(new)
    @raw_data = new
    @score = nil
    @image = nil
  end

  def score
    @raw_data ||= stories
    synthesize
    @score ||= student_point_std
  end

  def image
    @raw_data ||= stories
    synthesize
    @image ||= { chartType: 'point_distribution',
                 textTitle: 'Point Distribution',
                 data: @student_points }.to_json
  end

  def self.credentials
    %I[tracker_project tracker_token]
  end

  private

  def stories
    JSON.parse(@conn.get("projects/#{@project}/stories").body)
  end

  def memberships
    JSON.parse(@conn.get("projects/#{@project}/memberships").body)
  end

  def synthesize
    @raw_data ||= stories
    @student_points = @raw_data.inject(Hash.new(0)) do |sum, story|
      if %I[finished delivered accepted].include? story['current_state'].to_sym
        story['owner_ids'].each do |owner|
          sum[id2name[owner]] += story['estimate'].nil? ? 0 : story['estimate']
        end
      end
      sum
    end
  end

  def student_point_std
    values = @student_points.map { |_, v| v }
    sum = values.inject(0.0) { |sum, v| sum + v }
    mean = sum / values.length.to_f
    variance = values.inject(0.0) { |sum, v| sum + (v - mean)**2 }
    Math.sqrt(variance / (values.length - 1).to_f)
  end

  def id2name
    @id2name unless @id2name.empty?
    memberships.each do |mem|
      @id2name[mem['person']['id']] = mem['person']['name']
    end
    @id2name
  end
end

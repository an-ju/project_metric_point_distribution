require "project_metric_point_distribution/version"
require 'project_metric_point_distribution/test_generator'
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
  end

  def refresh
    set_stories
    set_memberships
    @raw_data = { stories: @stories, memberships: @memberships }.to_json
  end

  def raw_data=(new)
    @raw_data = new
    @score = nil
    @image = nil
  end

  def score
    refresh unless @raw_data
    scheduled_stories.empty? ? 0 : finished_stories.length.to_f / scheduled_stories.length.to_f
  end

  def image
    refresh unless @raw_data
    @image ||= { chartType: 'point_distribution',
                 data: { unstarted: stories_at(['unstarted']),
                         planned: stories_at(['planned']),
                         started: stories_at(['started']),
                         finished: stories_at(['finished']),
                         delivered: stories_at(['delivered']),
                         tracker_link: "https://www.pivotaltracker.com/n/projects/#{@project}"
                 } }.to_json
  end

  def commit_sha
    refresh unless @raw_data
    nil
  end

  def self.credentials
    %I[tracker_project tracker_token]
  end

  private

  def set_stories
    @stories = JSON.parse(@conn.get("projects/#{@project}/stories").body)
  end

  def set_memberships
    @memberships = JSON.parse(@conn.get("projects/#{@project}/memberships").body)
  end

  def name_of(uid)
    @memberships.select { |mem| mem['person']['id'].eql? uid }.first
  end

  def scheduled_stories
    stories_at %w[unstarted planned started finished delivered]
  end

  def finished_stories
    stories_at %w[finished delivered]
  end

  def stories_at(state_list)
    @stories.select { |s| state_list.any? { |state| s['current_state'].eql? state } }
  end
end

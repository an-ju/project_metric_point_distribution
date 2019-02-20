require "project_metric_point_distribution/version"
require 'project_metric_point_distribution/test_generator'
require 'faraday'
require 'json'
require 'project_metric_base'

class ProjectMetricPointDistribution
  include ProjectMetricBase
  add_credentials %I[tracker_project tracker_token]
  add_raw_data %w[tracker_stories tracker_memberships]

  def initialize(credentials, raw_data = nil)
    @project = credentials[:tracker_project]
    @conn = Faraday.new(url: 'https://www.pivotaltracker.com/services/v5')
    @conn.headers['Content-Type'] = 'application/json'
    @conn.headers['X-TrackerToken'] = credentials[:tracker_token]

    complete_with raw_data
    @max_iter = 0
  end

  def score
    scheduled_stories.empty? ? 0 : (finished_stories.length.to_f / scheduled_stories.length.to_f) * 100.0
  end

  def image
    { chartType: 'point_distribution',
      data: { unstarted: stories_at(['unstarted']),
              planned: stories_at(['planned']),
              started: stories_at(['started']),
              finished: stories_at(['finished']),
              delivered: stories_at(['delivered']),
              tracker_link: "https://www.pivotaltracker.com/n/projects/#{@project}" } }
  end

  def obj_id
    nil
  end

  private

  def tracker_stories
    @tracker_stories = JSON.parse(@conn.get("projects/#{@project}/stories").body)
  end

  def tracker_memberships
    @tracker_memberships = JSON.parse(@conn.get("projects/#{@project}/memberships").body)
  end

  def name_of(uid)
    @tracker_memberships.select { |mem| mem['person']['id'].eql? uid }.first
  end

  def scheduled_stories
    stories_at %w[unstarted planned started finished delivered]
  end

  def finished_stories
    stories_at %w[finished delivered]
  end

  def stories_at(state_list)
    @tracker_stories.select { |s| state_list.any? { |state| s['current_state'].eql? state } }
  end
end

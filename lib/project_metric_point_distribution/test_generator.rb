class ProjectMetricPointDistribution
  def self.fake_data
    [ fake_metric(unstarted: 2, started: 2, finished: 2, delivered: 2),
      fake_metric(unstarted: 3, started: 3, finished: 0, delivered: 0),
      fake_metric(unstarted: 0, started: 2, finished: 3, delivered: 3) ]

  end

  def self.fake_metric(stories)
    image_data = {
        unstarted: [],
        planned: [],
        started: [],
        finished: [],
        delivered: [],
        tracker_link: 'https://www.pivotaltracker.com/n/projects/2200655' }
    stories.each do |k, v|
      image_data[k] += Array.new(v) { fake_story(k) }
    end
    finished = stories.select { |k, v| k.eql?(:finished) or k.eql?(:delivered) }
    finished = finished.values.reduce(:+)
    all_stories = stories.values.reduce(:+)
    { image: { chatType: 'point_distribution', data: image_data }.to_json,
      score: finished.to_f / all_stories.to_f }
  end


  def self.fake_story(state)
    {
        "kind": "story",
        "id": 561+rand(100),
        "created_at": 1541505600000 + rand(100),
        "updated_at": 1541505600000 + 100 + rand(100),
        "story_type": "feature",
        "name": "Tractor beam loses power intermittently",
        "current_state": state,
        "requested_by_id": 102,
        "url": "http://localhost/story/show/561",
        "project_id": 99,
        "owner_ids":
            [
            ],
        "labels":
            [
            ]
    }
  end

end
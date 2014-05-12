class Migration::Event::CachePush
  def self.migrate
    ActiveRecord::Base.observers.disable(:all)

    fixed_new = 0
    fixed_old = 0
    strange_events = []

    ActiveRecord::Base.uncached do
      events_without_commits = Event.where(action: 'pushed', target_type: 'Project')

      events_without_commits.find_each do |event|
        if new_broken_event?(event)

          push = Push.find(event.data['id'])
          if push.project
            push.fill_push_data
            push.save
          end

          event.source = push
          event.data = push.attributes
          event.save

          fixed_new += 1
        elsif old_without_push_event?(event) && event.target

          push = Push.new(project_id: event.target_id, user_id: event.author_id,
                          revbefore: event.data["before"], revafter: event.data["after"],
                          ref: event.data["ref"])

          push.data = event.data
          push.save

          event.source = push
          event.data = push.attributes
          event.save

          fixed_old += 1
        else
          strange_events << event.id
        end
      end
    end

    p "fixed new: #{fixed_new}"
    p "fixed old: #{fixed_old}"
    p "strange: #{strange_events.count}"
  end

  private

  #:id => 488980,
  #:author_id => 2956,
  #:action => "pushed",
  #:source_id => 1442,
  #:source_type => "Push",
  #:target_id => 3694,
  #:target_type => "Project",
  #:data => {
  #    "id" => 1442,
  #    "ref" => "refs/heads/feature/animation_pub_content",
  #    "revbefore" => "48ae5208066b9e319bd679a4ed834f5dcdd4d531",
  #    "revafter" => "dcb46a3f36ae462eec7455da6e8fb01e02919607",
  #    "data" => nil,
  #    "project_id" => 3694,
  #    "user_id" => 2956,
  #    "commits_count" => nil,
  #    "created_at" => "2014-02-10T07:19:55.353Z",
  #    "updated_at" => "2014-02-10T07:19:55.353Z"
  #},
  #:created_at => Mon, 10 Feb 2014 07:19:55 UTC +00:00,
  #:updated_at => Mon, 10 Feb 2014 07:19:55 UTC +00:00,
  #:parent_event_id => 488979,
  #:system_action => "create"
  def self.new_broken_event?(event)
    data = event.data
    data.try(:[], 'data').blank? && data["id"] && Push.exists?(id: data['id'])
  end

  #:id => 222333,
  #:author_id => 2818,
  #:action => "pushed",
  #:source_id => nil,
  #:source_type => "Push_summary",
  #:target_id => 3175,
  #:target_type => "Project",
  #:data => {
  #    "before" => "852b378ba9516890ddb8ce50c3d5e9c9f1cb2e42",
  #    "after" => "bc016fb19bc5c0873017632fb8b4e8bd8fb1dc46",
  #    "ref" => "refs/heads/master",
  #    "user_id" => 2818,
  #    "user_name" => "dvasiliev",
  #    "repository" => {
  #        "name" => "nix-pkgs",
  #        "url" => "git@gitlab.undev.cc:megaadmins/nix-pkgs.git",
  #        "description" => "Репозиторий Undev для Nix.",
  #        "homepage" => "http://gitlab.undev.cc/megaadmins/nix-pkgs"
  #    },
  #    "commits" => [
  #      [0] {
  #        "id" => "3b151b4374d1a2e538e253dbab90d9d2b839c084",
  #        "message" => "videosearch algoritm nix version build && patches for log4cxx",
  #        "timestamp" => "2013-04-27T09:51:30+00:00",
  #        "url" => "http://gitlab.undev.cc/megaadmins/nix-pkgs/commit/3b151b4374d1a2e538e253dbab90d9d2b839c084",
  #        "author" => {
  #            "name" => "Vasiliev Dmitry",
  #            "email" => "vadv.mkn@gmail.com"
  #        }
  #      },
  #      [1] {
  #        "id" => "bc016fb19bc5c0873017632fb8b4e8bd8fb1dc46",
  #        "message" => "cmake flags fixes in videosearch-alg.nix",
  #        "timestamp" => "2013-04-27T12:54:09+00:00",
  #        "url" => "http://gitlab.undev.cc/megaadmins/nix-pkgs/commit/bc016fb19bc5c0873017632fb8b4e8bd8fb1dc46",
  #        "author" => {
  #            "name" => "Vasiliev Dmitry",
  #            "email" => "vadv.mkn@gmail.com"
  #        }
  #      }
  #    ],
  #    "total_commits_count" => 2
  #},
  #:created_at => Sat, 27 Apr 2013 12:54:28 UTC +00:00,
  #:updated_at => Sat, 27 Apr 2013 12:54:28 UTC +00:00,
  #:parent_event_id => nil,
  #:system_action => nil
  def self.old_without_push_event?(event)
    data = event.data
    data.has_key?('commits') && data.has_key?('before') && data.has_key?('after')
  end
end

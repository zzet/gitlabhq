class EventSummaryMailer < ActionMailer::Base
  include Gitlab::DiffUtils
  layout 'event_summary_email'
  helper :application, :commits, :tree, :gitlab_markdown
  helper_method :template_name, :prepare_data, :load_diff_data
  default from: "Gitlab messenger <#{Gitlab.config.gitlab.email_from}>",
          return_path: Gitlab.config.gitlab.email_from

  default_url_options[:host]        = Gitlab.config.gitlab.host
  default_url_options[:protocol]    = Gitlab.config.gitlab.protocol
  default_url_options[:port]        = Gitlab.config.gitlab.port unless Gitlab.config.gitlab_on_standard_port?
  default_url_options[:script_name] = Gitlab.config.gitlab.relative_url_root

  def daily_digest(user_id, events_ids, events_summary_id, current_time)
    @user           = User.find(user_id)
    @events         = Event.where(id: events_ids)

    @groupped_events = events_groupped_by_targets(@events)

    @events_summary = Event::Summary.find(events_summary_id)
    @current_time   = current_time

    mail(bcc: @user.email, subject: @events_summary.title)
  end

  def weekly_digest(user_id, events_ids, events_summary_id, current_time)
    @user           = User.find(user_id)
    @events         = Event.where(id: events_ids)

    @groupped_events = events_groupped_by_targets(@events)

    @events_summary = Event::Summary.find(events_summary_id)
    @current_time   = current_time

    mail(bcc: @user.email, subject: @events_summary.title)
  end

  def monthly_digest(user_id, events_ids, events_summary_id, current_time)
    @user           = User.find(user_id)
    @events         = Event.where(id: events_ids)

    @groupped_events = events_groupped_by_targets(@events)

    @events_summary = Event::Summary.find(events_summary_id)
    @current_time   = current_time

    mail(bcc: @user.email, subject: @events_summary.title)
  end

  private

  #{
  #  "Project"=> {
  #    :events=> []
  #    :events_count=>58,
  #    :grouped_events=> {
  #      3104=> {
  #        :events=> []
  #        :events_count=>58,
  #        :grouped_events=> {
  #
  #          "MergeRequest"=> {
  #            :events=> []
  #            :events_count=>4
  #          },
  #
  #          "Note"=> {
  #            :events=> []
  #            :events_count=>1
  #          },
  #
  #            "Push"=> {
  #            :events=> []
  #            :events_count=>53
  #          }
  #        }
  #      }
  #    }
  #  }
  #}
  def events_groupped_by_targets(events)
     events_targets = events.pluck(:target_type).uniq
     events_by_targets = events_targets.inject({}) do |res, target|
      target_events = events.where(target_type: target)

      res[target] = {
        events: target_events,
        events_count: target_events.count,
        grouped_events: events_groupped_by_targets_ids(target_events)
      }

      res
    end

    events_by_targets
  end

  def events_groupped_by_targets_ids(events)
    events_targets = events.pluck(:target_id).uniq
    event_ids = events.pluck(:id)
    events_by_targets_ids = events_targets.inject({}) do |res, target_id|
      target_events = Event.where(id: event_ids, target_id: target_id)

      res[target_id] = {
        events: target_events,
        events_count: target_events.count,
        grouped_events: events_groupped_by_sources(target_events)
      }

      res
    end

    events_by_targets_ids
  end

  def events_groupped_by_sources(events)
    events_sources = events.pluck(:source_type).uniq
    event_ids = events.pluck(:id)
    events_by_sources = events_sources.inject({}) do |res, source_type|
      source_events = Event.where(id: event_ids, source_type: source_type)

      res[source_type] = {
        events: source_events,
        events_count: source_events.count,
        grouped_events: events_groupped_by_source_ids(source_events)
      }

      res
    end

    events_by_sources
  end

  def events_groupped_by_source_ids(events)
    events_sources = events.pluck(:source_id).uniq
    event_ids = events.pluck(:id)
    events_by_sources_ids = events_sources.inject({}) do |res, source_id|
      source_events = Event.where(id: event_ids, source_id: source_id)

      res[source_id] = {
        events: source_events,
        events_count: source_events.count
      }

      res
    end

    events_by_sources_ids
  end

  def template_name(event)
    "event_summary_mailer/#{event.target_type.underscore}/#{event.source_type.underscore}/#{event.action}"
  end

  def prepare_data(event)
    result = {}

    result[:event] = event
    result[:user] = event.author
    result[:data] = event.data

    result
  end


  helper do
    def diff(new_str, old_str)
      diff = Diffy::Diff.new(old_str, new_str)
      diff.to_s(:html).html_safe
    end

    def find_entity(type, id, event = nil)
      klass = case type
              when String
                type.constantize
              when Symbol
                type.to_s.camelize.constantize
              else
                type
              end

      entity = klass.find_by(id: id)
      unless entity
        unless event
          event = @events.find_by(source_id: id, source_type: type,
                                  target_id: id, target_type: type,
                                  action: :deleted)
        end
        begin
          attrs = ActionController::Parameters.new(event.data)
          #attrs.permit!

          entity = klass.new
          attrs.each_pair do |k, v|
            entity.send(k, v)
          end
        rescue
        end
      end
      entity
    end

    def template_arguments(event)
      {
        event: event,
        author: event.author,
        source: event.source || find_entity(event.source_type, event.source_id, event),
        target: event.target || find_entity(event.target_type, event.target_id),
        data: event.data
      }
    end

    def template_exists?(name)
      chunks = name.split('/')
      template = chunks.pop
      namespace = if chunks.blank?
                    "event_summary_mailer"
                  else
                    chunks.join('/')
                  end
      lookup_context.template_exists?(template, namespace, true)
    end

    def mailer_project_link(project)
      if project && project.persisted?
        "#{link_to(project.name_with_namespace, project_url(project.path_with_namespace))}".html_safe
      else
        "<b>#{project.try(:name_with_namespace)} (#{ project.try(:path_with_namespace) })</b>".html_safe
      end
    end

    def mailer_group_link(group)
      if group.persisted?
        "#{link_to(group.name, group_url(group.path))}".html_safe
      else
        "<b>#{group.try(:name)} (#{ group.try(:path) })</b>".html_safe
      end
    end

    def mailer_team_link(team)
      if team.persisted?
        "#{link_to(team.name, team_url(team.path))}".html_safe
      else
        "<b>#{team.try(:name)} (#{ team.try(:path) })</b>".html_safe
      end
    end

    def mailer_issue_link(issue)
      if issue.persisted?
        "#{link_to(issue.title, project_issue_url(project.path_with_namespace, issue.iid))}".html_safe
      else
        "<b>#{issue.try(:title)} (##{ issue.try(:iid) })</b>".html_safe
      end
    end

    def mailer_milestone_link(milestone)
      if milestone.persisted?
        "#{link_to(milestone.title, project_milestone_url(project.path_with_namespace, milestone))}".html_safe
      else
        "<b>#{milestone.try(:title)}</b>".html_safe
      end
    end

    def mailer_merge_request_link(merge_request)
      if merge_request.persisted?
        "#{link_to(merge_request.title, project_merge_request_url(merge_request.project.path_with_namespace, merge_request.iid))}".html_safe
      else
        "<b>#{merge_request.try(:title)} (##{ merge_request.try(:iid) })</b>".html_safe
      end
    end

    def mailer_user_link(user)
      if user.persisted?
        "#{link_to(user.name, user_url(user.username))}".html_safe
      else
        "<b>#{user.try(:name)} (#{ user.try(:username) })</b>".html_safe
      end
    end

    def mailer_permission_name(permission)
      if permission
        Gitlab::Access.options.key(permission)
      else
        false
      end
    end

    def mailer_source_type_human(source_type)
      case source_type
      when "UsersProject"
        "User membership in project"
      when "MergeRequest"
        "Merge Request"
      when "ProjectHook"
        "Project Hooks"
      when "ProtectedBranch"
        "Protected Branches"
      when "TeamProjectRelationship"
        "Relation between team and project"
      when "UsersGroup"
        "User membership in group"
      when "TeamUserRelationship"
        "User membership in team"
      when "TeamGroupRelationship"
        "Relation between team and group"
      else
        source_type
      end.pluralize
    end
  end
end

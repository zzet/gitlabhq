class ActivityObserver < ActiveRecord::Observer
  observe :issue,           # +
          :merge_request,   # +
          :key,             # +
          :milestone,       # +
          :group,           # +
          :note,            # +
          :project,         # +
          :protected_branch,# +
          :service,         # +
          :snippet,         # +
          :user,            # +
          :team,       # +
          :team_project_relationship,
          :team_group_relationship,
          :team_user_relationship,
          :users_project,   # +
          :users_group,   # +
          :project_hook,    # +
          :system_hook

  #def after_create(model)
    #Gitlab::Event::Action.trigger :created, model
  #end

  #def around_transition(model, transition)
    #RequestStore.store[:borders] ||= []
    #RequestStore.store[:borders].push("gitlab.#{transition.event}.#{model.class.name.underscore}")
    #yield
    ##EventHierarchyWorker.reset
    #Gitlab::Event::Action.trigger :"#{transition.event}", model
    #RequestStore.store[:borders].pop
  #end

  #def before_transition(model, transition)
    #RequestStore.store[:borders] ||= []
    #RequestStore.store[:borders].push("gitlab.#{transition.event}.#{model.class.name.underscore}")
  #end

  #def after_transition(model, transition)
    #EventHierarchyWorker.reset
    #Gitlab::Event::Action.trigger :"#{transition.event}", model
    #RequestStore.store[:borders].pop
  #end

  #def after_failure_to_transition(model, transition)
    #Rails.logger.info "gitlab.#{transition.event}.#{model.class.name} fail"
    #RequestStore.store[:borders].pop
  #end

  def updated_by_system?(model)
    project_system_update?(model) || user_system_update?(model)
  end

  def project_system_update?(model)
    return false unless model.is_a? ::Project
    return false if model.changes.count != 2
    return true if model.changes[:last_activity_at].present?
    return true if model.changes[:last_pushed_at].present?
    false
  end

  def user_system_update?(model)
    return false unless model.is_a? ::User
    return false if model.changes.count != 4
    return true if model.changes[:last_sign_in_at].present?
    false
  end
end

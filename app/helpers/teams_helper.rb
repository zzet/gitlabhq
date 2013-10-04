module TeamsHelper
  def remove_user_from_team_message(team, user)
    "You are going to remove #{user.name} member from #{team.name} Team. Are you sure?"
  end

  def remove_project_from_team_message(team, project)
    "You are going to remove #{project.name_with_namespace} project from #{team.name} Team. Are you sure?"
  end

  def remove_group_from_team_message(team, group)
    "You are going to remove #{group.name} group from #{team.name} Team. Are you sure?"
  end

  def remove_team_message(team)
    "You are going to remove #{team.name} Team. Are you sure?"
  end
end

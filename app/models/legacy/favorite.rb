class Legacy::Favorite < LegacyDb
  belongs_to :user
  belongs_to :watchable, :polymorphic => true

  named_scope :visible_by, Proc.new { |user|
    user = Legacy::User.new({ :id => 0, :is_admin => false }) unless user.is_a?(Legacy::User)
    {
      :conditions => [
        "favorites.watchable_type = :project and exists (
          select projects.id from projects
          where projects.id = favorites.watchable_id and
          (
            projects.private = :private
            or projects.owner_type = :user and projects.owner_id = :user_id
            or projects.owner_type = :group and exists (
              select u1.id
              from users as u1
              inner join memberships as m1 on m1.user_id = u1.id
              where u1.id = :user_id and m1.group_id = projects.owner_id
            )
            or exists (
              select c.id from committerships as c
              inner join repositories as r on c.repository_id = r.id
              where r.project_id = projects.id and (
                c.committer_type = :user and c.committer_id = :user_id
                or c.committer_type = :group and exists (
                  select u2.id
                  from users as u2
                  inner join memberships as m2 on m2.user_id = u2.id
                  where u2.id = :user_id and m2.group_id = c.committer_id
                )
              )
            )
          )
        )
        or favorites.watchable_type = :repository and exists (
          select repositories.id from repositories
          join projects on repositories.project_id = projects.id
          where repositories.id = favorites.watchable_id and
          (
            projects.private = :private
            or projects.owner_type = :user and projects.owner_id = :user_id
            or projects.owner_type = :group and exists (
              select u1.id
              from users as u1
              inner join memberships as m1 on m1.user_id = u1.id
              where u1.id = :user_id and m1.group_id = projects.owner_id
            )
            or exists (
              select c.id
              from committerships as c
              where c.repository_id = repositories.id and
              (c.committer_type = :user and c.committer_id = :user_id
              or c.committer_type = :group and exists (
                select u2.id
                from users as u2
                inner join memberships as m2 on m2.user_id = u2.id
                where u2.id = :user_id and m2.group_id = c.committer_id)
              )
            )
          )
        )
        or favorites.watchable_type = :merge_request and exists (
          select merge_requests.id from merge_requests
          join repositories on merge_requests.target_repository_id = repositories.id
          join projects on repositories.project_id = projects.id
          where merge_requests.id = favorites.watchable_id and
          (
            projects.private = :private
            or projects.owner_type = :user and projects.owner_id = :user_id
            or projects.owner_type = :group and exists (
              select u1.id
              from users as u1
              inner join memberships as m1 on m1.user_id = u1.id
              where u1.id = :user_id and m1.group_id = projects.owner_id
            )
            or exists (
              select c.id
              from committerships as c
              where
                c.repository_id = repositories.id and
                (c.committer_type = :user and c.committer_id = :user_id
                or c.committer_type = :group and exists (
                  select u2.id
                  from users as u2
                  inner join memberships as m2 on m2.user_id = u2.id
                  where u2.id = :user_id and m2.group_id = c.committer_id)
                )
            )
          )
        )",
        {
          :project => "Project",
          :repository => "Repository",
          :user => "User",
          :group => "Group",
          :merge_request => "MergeRequest",
          :user_id => user.id,
          :private => false
        }
      ]
    } unless user.site_admin?
  }

  def event_exists?
    !Legacy::Event.count(:conditions => event_options).zero?
  end

  def event_options
    {:action => Legacy::Action::ADD_FAVORITE, :data => watchable.id,
      :body => watchable.class.name, :project_id => project.id,
      :target_type => "User", :target_id => user.id}
  end

  def project
    case watchable
    when Legacy::MergeRequest
      watchable.target_repository.project
    when Legacy::Repository
      watchable.project
    when Legacy::Project
      watchable
    end
  end

  def event_should_be_created?
    !event_exists?
  end

end

# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class FeedItem < LegacyDb
  belongs_to :event
  belongs_to :watcher, :class_name => "User"

  named_scope :visible_by, Proc.new { |user|
    user = User.new({ :id => 0, :is_admin => false }) unless user.is_a?(User)
    {
      :conditions => [
        "events.target_type = :project and exists (
          select projects.id from projects
          where
            projects.id = events.target_id
            and (projects.private = :private
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
            ))
        )
        or events.target_type = :repository and exists (
          select repositories.id
          from repositories
          join projects on repositories.project_id = projects.id
          where
            repositories.id = events.target_id
            and (projects.private = :private
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
              ))
        )", {
          :project => "Project",
          :repository => "Repository",
          :user => "User",
          :group => "Group",
          :user_id => user.id,
          :private => false
        }
      ],
      :joins => :event
    } unless user.site_admin?
  }

  def self.bulk_create_from_watcher_list_and_event!(watcher_ids, event)
    return if watcher_ids.blank?
    # Build a FeedItem for all the watchers interested in the event
    sql_values = watcher_ids.map do |an_id|
      "(#{an_id}, #{event.id}, '#{event.created_at.to_s(:db)}', '#{event.created_at.to_s(:db)}')"
    end
    sql = %Q{INSERT INTO feed_items (watcher_id, event_id, created_at, updated_at)
             VALUES #{sql_values.join(',')}}
    LegacyDb.connection.execute(sql)
  end

end

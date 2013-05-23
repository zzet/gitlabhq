module Gitlab
  module Event
    class SeedBuilder
      def initialize
        ActiveRecord::Base.observers.disable :all

        import_source_code
      end

      def create_push_event
        unless ::Event.find_by_author_id user.id
          push_data = GitPushService.new.sample_data(project, user)

          event = FactoryGirl.create :event, {
            action: :pushed,
            data: push_data.to_json,
            author_id: user.id,
            source_id: nil,
            source_type: "Push_summary",
            target_id: project.id,
            target_type: 'Project'
          }

          subscription = FactoryGirl.create :subscription, {
            action: :pushed,
            user: user,
            target_id: project.id,
            target_type: 'Project'
          }

          FactoryGirl.create :notification, {
            event: event,
            subscription: subscription,
            subscriber: user
          }
        end
      end

      private

      def path
        'notification_test_repo'
      end

      def git_repo
        'https://github.com/documentcloud/underscore.git'
      end

      def project
        @project ||= Project.find_by_path path
        @project ||= FactoryGirl.create :project, {
          name: 'notification_test_project',
          path: path,
          creator: user,
          default_branch: 'master'
        }
      end

      def user
        @user ||= User.find_by_email "notification_tester@example.com"
        @user ||= FactoryGirl.create :user, {
          name: "Notification Tester",
          email: 'notification_tester@example.com',
        }
      end

      def import_source_code
        root = Gitlab.config.gitlab_shell.repos_path

        project_path = File.join(root, path + '.git')

        if File.exists?(project_path)
          print '-'
        else
          shell = Gitlab::Shell.new
          if shell.import_repository(project.path_with_namespace, git_repo)
            print '.'
          else
            print 'F'
          end
        end
      end
    end
  end
end


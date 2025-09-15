module AppNotificationsIssuesPatch
  def self.included(base)
    base.class_eval do
      after_create :notify_issue_created
      after_update :notify_issue_updated, if: :saved_change_to_assigned_to_id?

      private

      def notify_issue_created
        return unless Setting.plugin_redmine_app_notifications['enable_notifications'] == '1'
        
        allowed_roles = ["Crew Lead", "Mission Element Lead", "Team Lead"]
        recipients = []
        
        # Add assigned user
        if assigned_to.present? && assigned_to.is_a?(User)
          recipients << assigned_to
        end
        
        # Add users with allowed roles in this project
        User.active.includes(:memberships => :roles).each do |user|
          user_roles = user.roles_for_project(project).map(&:name)
          if (user_roles & allowed_roles).any?
            recipients << user
          end
        end
        
        recipients.uniq.each do |user|
          AppNotification.create_for_issue(self, user, 'created')
        end
      end

      def notify_issue_updated
        return unless Setting.plugin_redmine_app_notifications['enable_notifications'] == '1'
        
        allowed_roles = ["Crew Lead", "Mission Element Lead", "Team Lead"]
        recipients = []
        
        # Add new assignee
        if assigned_to.present? && assigned_to.is_a?(User)
          recipients << assigned_to
        end
        
        # Add users with allowed roles in this project
        User.active.includes(:memberships => :roles).each do |user|
          user_roles = user.roles_for_project(project).map(&:name)
          if (user_roles & allowed_roles).any?
            recipients << user
          end
        end
        
        recipients.uniq.each do |user|
          AppNotification.create_for_issue(self, user, 'updated')
        end
      end
    end
  end
end

unless Issue.included_modules.include?(AppNotificationsIssuesPatch)
  Issue.send(:include, AppNotificationsIssuesPatch)
end

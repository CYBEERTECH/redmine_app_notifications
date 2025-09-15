module AppNotificationsJournalsPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      after_create :notify_case_changes
    end
  end

  module InstanceMethods
  def notify_case_changes
      return if recipients.nil?
      recips = recipients.uniq.reject { |u| u == User.current }
      
      # Check for status or assignee changes
      status_changed = details.any? { |d| d.prop_key == 'status_id' }
      assignee_changed = details.any? { |d| d.prop_key == 'assigned_to_id' }
      
      return unless status_changed || assignee_changed

      # unified roles + groups filter
      allowed_roles = ["Crew Lead", "Mission Element Lead", "Team Lead"]
      allowed_groups = ["Operations", "Supervisors"]
      User.active.includes(:memberships => :roles).each do |u|
        user_roles = u.roles_for_project(self.journalized.project).map(&:name)
        recipients << u if (user_roles & allowed_roles).any? || (u.groups.map(&:name) & allowed_groups).any?
      end      
      
      # Remove duplicates and current user
      recipients = (recipients || []).uniq.reject { |u| u == User.current }
      
      # Create notifications
      recipients.each do |user|
        AppNotification.create_for_journal(self, user)
      end
    end
  end
end

unless Journal.included_modules.include?(AppNotificationsJournalsPatch)
  Journal.send(:include, AppNotificationsJournalsPatch)
end

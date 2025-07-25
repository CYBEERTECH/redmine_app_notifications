module AppNotificationsJournalsPatch
  def self.included(base)
    base.class_eval do
      after_create :create_app_notification_for_journal
    end
  end

  private

  def create_app_notification_for_journal
    return unless Setting.plugin_redmine_app_notifications['enable_notifications']
    return unless journalized.is_a?(Issue)
    
    issue = journalized
    
    # Notify assigned user
    if issue.assigned_to && issue.assigned_to.is_a?(User) && issue.assigned_to.app_notifications_enabled?
      AppNotification.create_for_journal(self, issue.assigned_to)
    end
    
    # Notify watchers
    issue.watcher_users.each do |user|
      next unless user.app_notifications_enabled?
      AppNotification.create_for_journal(self, user)
    end
  end
end

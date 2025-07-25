module AppNotificationsIssuesPatch
  def self.included(base)
    base.class_eval do
      after_create :create_app_notification_for_creation
      after_update :create_app_notification_for_update
    end
  end

  private

  def create_app_notification_for_creation
    return unless Setting.plugin_redmine_app_notifications['enable_notifications']
    
    # Notify assigned user
    if assigned_to && assigned_to.is_a?(User) && assigned_to.app_notifications_enabled?
      AppNotification.create_for_issue(self, assigned_to, 'created')
    end
    
    # Notify watchers
    watcher_users.each do |user|
      next unless user.app_notifications_enabled?
      AppNotification.create_for_issue(self, user, 'created')
    end
  end

  def create_app_notification_for_update
    return unless Setting.plugin_redmine_app_notifications['enable_notifications']
    return unless saved_changes.any?
    
    # Notify assigned user if changed
    if assigned_to && assigned_to.is_a?(User) && assigned_to.app_notifications_enabled?
      AppNotification.create_for_issue(self, assigned_to, 'updated')
    end
    
    # Notify watchers
    watcher_users.each do |user|
      next unless user.app_notifications_enabled?
      AppNotification.create_for_issue(self, user, 'updated')
    end
  end
end

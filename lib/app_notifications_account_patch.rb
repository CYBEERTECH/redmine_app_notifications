module AppNotificationsAccountPatch
  def self.included(base)
    base.class_eval do
      has_many :app_notifications, :dependent => :destroy
      
      safe_attributes 'app_notifications_enabled',
                      'app_notification_sound_enabled',
                      'rfi_notification_preferences'
    end
  end

  def app_notifications_enabled?
    app_notifications_enabled.nil? ? true : app_notifications_enabled
  end

  def app_notification_sound_enabled?
    app_notification_sound_enabled.nil? ? true : app_notification_sound_enabled
  end

  def rfi_notification_preferences
    return [] if self[:rfi_notification_preferences].blank?
    JSON.parse(self[:rfi_notification_preferences]) rescue []
  end

  def rfi_notification_preferences=(prefs)
    self[:rfi_notification_preferences] = prefs.is_a?(Array) ? prefs.to_json : prefs
  end

  def wants_rfi_notification?(issue)
    return false unless roles_for_project(issue.project).map(&:name).include?("Team Lead")
    
    prefs = rfi_notification_preferences
    return true if prefs.empty? # Default to all RFIs if no preferences set
    
    # Check if this RFI matches user's preferences
    prefs.any? do |pref|
      case pref['type']
      when 'project'
        issue.project_id.to_s == pref['value']
      when 'priority'
        issue.priority&.name == pref['value']
      when 'category'
        issue.category&.name == pref['value']
      when 'tracker'
        issue.tracker&.name == pref['value']
      else
        false
      end
    end
  end
end

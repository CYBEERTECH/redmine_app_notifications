module AppNotificationsAccountPatch
  def self.included(base)
    base.class_eval do
      has_many :app_notifications, :dependent => :destroy
      
      safe_attributes 'app_notifications_enabled',
                      'app_notification_sound_enabled'
    end
  end

  def app_notifications_enabled?
    app_notifications_enabled.nil? ? true : app_notifications_enabled
  end

  def app_notification_sound_enabled?
    app_notification_sound_enabled.nil? ? true : app_notification_sound_enabled
  end
end

require 'redmine'

Redmine::Plugin.register :redmine_app_notifications do
  name 'Redmine App Notifications plugin'
  author 'CYBEERTECH'
  forked from '
  description 'This is a plugin for Redmine '6.0' that provides in-app notifications'
  version '2.0.0'
  url 'https://github.com/dr-consit/redmine_app_notifications'
  author_url 'https://github.com/MichalVanzura/redmine_app_notifications'

  requires_redmine :version_or_higher => '6.0.0'

  settings :default => {
    'enable_notifications' => true,
    'notification_sound' => true,
    'auto_refresh' => 30
  }, :partial => 'settings/app_notifications_settings'

  menu :account_menu, :app_notifications, { :controller => 'app_notifications', :action => 'index' }, 
       :caption => :label_app_notifications, :if => Proc.new { User.current.logged? }

  permission :view_app_notifications, :app_notifications => [:index, :show]
  permission :manage_app_notifications, :app_notifications => [:destroy, :mark_as_read]
end

# Load patches
Rails.application.config.to_prepare do
  unless User.included_modules.include?(AppNotificationsAccountPatch)
    User.send(:include, AppNotificationsAccountPatch)
  end
  
  unless Issue.included_modules.include?(AppNotificationsIssuesPatch)
    Issue.send(:include, AppNotificationsIssuesPatch)
  end
  
  unless Journal.included_modules.include?(AppNotificationsJournalsPatch)
    Journal.send(:include, AppNotificationsJournalsPatch)
  end
  
  unless News.included_modules.include?(AppNotificationsNewsPatch)
    News.send(:include, AppNotificationsNewsPatch)
  end
end

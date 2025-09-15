require 'redmine'

Rails.logger.info "[AppNotifications] Plugin init.rb loading..."

Redmine::Plugin.register :redmine_app_notifications do
  name 'Redmine App Notifications plugin'
  author 'CYBEERTECH'
  description 'This is a plugin for Redmine that provides in-app notifications'
  version '0.0.1'
  url 'https://github.com/CYBEERTECH/redmine_app_notifications/'
  author_url 'https://github.com/MichalVanzura/redmine_app_notifications'

  requires_redmine :version_or_higher => '6.0.0'

  require_relative 'lib/app_notifications_issues_patch'
  require_relative 'lib/app_notifications_journals_patch'

settings :default => {
  'enable_notifications'     => '1',
  'notification_sound'       => '1',
  'auto_refresh'             => '60',
  'notify_group_ids'         => [],
  'notify_role_ids'          => [],
  'default_notification_type'=> 'realtime',
  'notify_target'            => 'group_and_role'
  }, :partial => 'settings/app_notifications_settings'

  menu :account_menu, :app_notifications, { :controller => 'app_notifications', :action => 'index' },
       :caption => :label_app_notifications, :if => Proc.new { User.current.logged? }

  permission :view_app_notifications, :app_notifications => [:index, :show]
  permission :manage_app_notifications, :app_notifications => [:destroy, :mark_as_read]
end

Rails.logger.info "[AppNotifications] Plugin registered, loading components..."

# Load hook listener and patches
Rails.application.config.to_prepare do
  Rails.logger.info "[AppNotifications] to_prepare block executing..."
  
  # Load hook listener
  begin
    require_dependency File.expand_path('../lib/app_notifications_hook_listener', __FILE__)
    Rails.logger.info "[AppNotifications] Hook listener loaded successfully"
  rescue => e
    Rails.logger.error "[AppNotifications] Failed to load hook listener: #{e.message}"
  end
  
  # Load account patch for User model
  begin
    require_dependency File.expand_path('../lib/app_notifications_account_patch', __FILE__)
    unless User.included_modules.include?(AppNotificationsAccountPatch)
      User.send(:include, AppNotificationsAccountPatch)
      Rails.logger.info "[AppNotifications] Account patch applied to User"
    else
      Rails.logger.info "[AppNotifications] Account patch already applied to User"
    end
  rescue => e
    Rails.logger.error "[AppNotifications] Failed to load account patch: #{e.message}"
  end
end

Rails.logger.info "[AppNotifications] Plugin init.rb completed"

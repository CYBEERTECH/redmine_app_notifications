class AppNotificationsHookListener < Redmine::Hook::Listener

  # Add bell icon to header and include assets
  def view_layouts_base_html_head(context = {})
    return '' unless User.current.logged?
    
    html = <<-HTML
      <link rel="stylesheet" type="text/css" href="/plugin_assets/redmine_app_notifications/stylesheets/app_notifications.css" />
      <script type="text/javascript" src="/plugin_assets/redmine_app_notifications/javascripts/app_notifications.js"></script>
      <script type="text/javascript" src="/plugin_assets/redmine_app_notifications/javascripts/mention_autocomplete.js"></script>
    HTML
    
    html.html_safe
  end

  def view_layouts_base_body_bottom(context = {})
    user = User.current
    return '' unless user.logged?
    
    unread_count = AppNotification.where(recipient_id: user.id, read: false).count
    
    html = <<-HTML
      <script type="text/javascript">
        document.addEventListener('DOMContentLoaded', function() {
          // Find the Notifications heading on the page
          var notificationsHeading = document.querySelector('h2');
          if (notificationsHeading && notificationsHeading.textContent.trim() === 'Notifications') {
            // Add bell icon inline with the heading text
            if (#{unread_count} > 0) {
              notificationsHeading.innerHTML = 'Notifications <span id="notification-bell" style="font-size: 20px; margin-left: 5px;">🔔</span>';
            }
          }
          
          // Also check for notifications in the account menu for other pages
          var accountMenu = document.querySelector('#account ul');
          if (accountMenu) {
            var myAccountLink = accountMenu.querySelector('a[href*="my/account"]');
            if (myAccountLink) {
              // Add notifications link to account menu if it doesn't exist
              var notifLink = accountMenu.querySelector('a[href="/app_notifications"]');
              if (!notifLink) {
                var notifLi = document.createElement('li');
                var bellText = #{unread_count} > 0 ? 'Notifications 🔔' : 'Notifications';
                notifLi.innerHTML = '<a href="/app_notifications" id="notification-menu-link">' + bellText + '</a>';
                myAccountLink.parentNode.parentNode.insertBefore(notifLi, myAccountLink.parentNode.nextSibling);
              }
            }
          }
        });
      </script>
    HTML
    
    html.html_safe
  end

  # Fires after a new issue is created
  def controller_issues_new_after_save(context = {})
    issue = context[:issue]
    return unless issue

    return unless Setting.plugin_redmine_app_notifications['enable_notifications'] == '1'

    allowed_roles  = ["Crew Lead", "Mission Element Lead", "Team Lead"]
    allowed_groups = ["Operations", "Supervisors"]

    recipients = []

    # Assigned user
    if issue.assigned_to.is_a?(User)
      recipients << issue.assigned_to
    end

    # Roles
    recipients |= issue.project.users.select do |u|
      (u.roles_for_project(issue.project).map(&:name) & allowed_roles).any?
    end

    # Groups
    recipients |= issue.project.users.select do |u|
      (u.groups.map(&:name) & allowed_groups).any?
    end

    recipients = recipients.uniq - [User.current]

    Rails.logger.info "[AppNotifications] Hook: Issue created ##{issue.id} -> #{recipients.map(&:name).join(', ')}"

    recipients.each do |u|
      AppNotification.create_for_issue(issue, u, 'created')
    end
    
    # Also notify assigned user specifically
    if issue.assigned_to.is_a?(User) && !recipients.include?(issue.assigned_to)
      AppNotification.create_for_issue(issue, issue.assigned_to, 'assigned')
    end
  end

  # Fires after an issue is updated (status, notes, assignment, etc.)
  def controller_issues_edit_after_save(context = {})
    issue   = context[:issue]
    journal = context[:journal]
    return unless issue && journal

    return unless Setting.plugin_redmine_app_notifications['enable_notifications'] == '1'

    has_field_changes = journal.details.any?
    has_notes         = journal.notes.present?
    return unless has_field_changes || has_notes

    allowed_roles  = ["Crew Lead", "Mission Element Lead", "Team Lead"]
    allowed_groups = ["Operations", "Supervisors"]

    recipients = []

    # Get all users who should be notified based on roles/groups
    User.active.includes(:memberships => :roles).each do |u|
      user_roles = u.roles_for_project(issue.project).map(&:name)
      if (user_roles & allowed_roles).any? || (u.groups.map(&:name) & allowed_groups).any?
        recipients << u
      end
    end

    # Add assigned user if they have assignment changes
    assignment_changed = journal.details.any? { |d| d.prop_key == 'assigned_to_id' }
    if assignment_changed && issue.assigned_to.is_a?(User)
      recipients << issue.assigned_to
    end

    # Check for @ mentions and add mentioned users
    if journal.notes.present?
      mentioned_users = extract_mentioned_users(journal.notes, issue.project)
      recipients |= mentioned_users
    end

    recipients = recipients.uniq.reject { |u| u == User.current }

    Rails.logger.info "[AppNotifications] Hook: Issue updated ##{issue.id}, journal ##{journal.id} -> #{recipients.map(&:name).join(', ')}"

    recipients.each do |u|
      AppNotification.create_for_journal(journal, u)
    end
  end

  private

  def extract_mentioned_users(text, project)
    mentioned_users = []
    # Find @username patterns
    text.scan(/@(\w+)/) do |match|
      username = match[0]
      user = User.active.find_by(login: username)
      if user && user.allowed_to?(:view_issues, project)
        mentioned_users << user
      end
    end
    mentioned_users
  end
end

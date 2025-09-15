class AppNotification < ActiveRecord::Base
  before_validation { self.recipient_id ||= self.user_id }
  scope :for_user, ->(user) { where("user_id = :id OR recipient_id = :id", id: user.id) }

  belongs_to :user
  belongs_to :issue, :optional => true
  belongs_to :journal, :optional => true
  belongs_to :news, :optional => true

  validates :user_id, :presence => true
  validates :title, :presence => true, :length => { :maximum => 255 }
  validates :message, :presence => true
  validates :url, :length => { :maximum => 500 }

  scope :unread, -> { where(:read => false) }
  scope :recent, -> { order(:created_at => :desc) }

  def self.allowed_recipient?(user, project, notification_type = 'general', issue = nil)
    user_roles = user.roles_for_project(project).map(&:name)
    group_names = user.groups.map(&:name)
    
    case notification_type
    when 'assignment', 'status_change'
      # Crew Lead, Mission Element Lead get assignment and status change notifications
      # Host Analyst and Network Analyst get assignment notifications
      allowed_roles = ["Crew Lead", "Mission Element Lead", "Host Analyst", "Network Analyst"]
      allowed_groups = ["Operations", "Supervisors"]
      
      # Team Lead only gets notifications for Critical/High severity or priority cases
      if user_roles.include?("Team Lead")
        return false unless issue && (
          (issue.priority && %w[Critical High].include?(issue.priority.name)) ||
          (issue.respond_to?(:severity) && issue.severity && %w[Critical High].include?(issue.severity.name))
        )
      end
      
      (user_roles & allowed_roles).any? || (group_names & allowed_groups).any? || user_roles.include?("Team Lead")
    when 'mention'
      # Analysts get @ mention notifications, plus leadership roles
      allowed_roles = ["Crew Lead", "Mission Element Lead", "Team Lead", "Host Analyst", "Network Analyst"]
      (user_roles & allowed_roles).any?
    when 'rfi_request'
      # Team Lead gets RFI request notifications based on preferences
      return false unless user_roles.include?("Team Lead")
      user.wants_rfi_notification?(issue)
    else
      # General notifications for leadership roles
      allowed_roles = ["Crew Lead", "Mission Element Lead", "Team Lead"]
      allowed_groups = ["Operations", "Supervisors"]
      (user_roles & allowed_roles).any? || (group_names & allowed_groups).any?
    end
  end

  def read?
    read == true
  end

  def mark_as_read!
    update_attribute(:read, true)
  end

def self.create_for_issue(issue, user, action)
    notification_type = case action
                       when 'assigned'
                         'assignment'
                       else
                         'general'
                       end
    
    return unless user && issue && allowed_recipient?(user, issue.project, notification_type, issue)
    
    Rails.logger.info "[AppNotifications] Creating notification for issue ##{issue.id}, user: #{user.name}, action: #{action}"
    
    title = case action
            when 'created'
              "Case ##{issue.id} created"
            when 'assigned'
              "Case ##{issue.id} assigned to you"
            when 'updated'
              "Case ##{issue.id} updated"
            else
              "Case ##{issue.id} changed"
            end
    message = "#{issue.subject}"
    url = Rails.application.routes.url_helpers.issue_path(issue)
    

begin
      notification = create!(
        :user => user,
        :issue => journal.issue,
        :journal => journal,
        :title => title,
        :message => message,
        :url => url,
        :read => false
      )

      Rails.logger.info "[AppNotifications] Successfully created notification ID: #{notification.id}"
      notification
    rescue => e
      Rails.logger.error "[AppNotifications] Failed to create notification: #{e.message}"
      nil
    end
  end

def self.create_for_journal(journal, user, *_extra)
    return unless user && journal && journal.issue
    
    # Determine notification type based on changes
    notification_type = 'general'
    has_status_change = journal.details.any? { |d| d.prop_key == 'status_id' }
    has_assignment_change = journal.details.any? { |d| d.prop_key == 'assigned_to_id' }
    has_mentions = journal.notes.present? && journal.notes.include?("@#{user.login}")
    
    if has_mentions
      notification_type = 'mention'
    elsif has_assignment_change || has_status_change
      notification_type = 'status_change'
    end
    
    return unless allowed_recipient?(user, journal.issue.project, notification_type, journal.issue)
    
    Rails.logger.info "[AppNotifications] Creating notification for journal ##{journal.id}, user: #{user.name}, type: #{notification_type}"
    
    # Build change description
    changes = []
    journal.details.each do |detail|
      case detail.prop_key
      when 'status_id'
        old_status = IssueStatus.find_by(id: detail.old_value)&.name || 'Unknown'
        new_status = IssueStatus.find_by(id: detail.value)&.name || 'Unknown'
        changes << "Status changed from #{old_status} to #{new_status}"
      when 'assigned_to_id'
        old_user = User.find_by(id: detail.old_value)&.name || 'Unassigned'
        new_user = User.find_by(id: detail.value)&.name || 'Unassigned'
        changes << "Assignee changed from #{old_user} to #{new_user}"
      end
    end
    
    title = case notification_type
            when 'mention'
              "You were mentioned in Case ##{journal.issue.id}"
            when 'status_change'
              "Case ##{journal.issue.id} updated"
            else
              "Case ##{journal.issue.id} updated"
            end
    
    message = if has_mentions
                "#{User.current.name} mentioned you: #{journal.notes.truncate(150)}"
              elsif changes.any?
                changes.join('; ')
              elsif journal.notes.present?
                journal.notes.truncate(200)
              else
                "Case updated"
              end
    url = Rails.application.routes.url_helpers.issue_path(journal.issue)
    
    begin
      notification = create!(
        :user => user,
        :issue => journal.issue,
        :journal => journal,
        :title => title,
        :message => message,
        :url => url,
        :read => false
      )
      Rails.logger.info "[AppNotifications] Successfully created notification ID: #{notification.id}"
      notification
    rescue => e
      Rails.logger.error "[AppNotifications] Failed to create notification: #{e.message}"
      nil
    end
  end
end

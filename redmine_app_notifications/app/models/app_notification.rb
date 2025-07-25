class AppNotification < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue, :optional => true
  belongs_to :journal, :optional => true
  belongs_to :news, :optional => true

  validates :user_id, :presence => true
  validates :title, :presence => true, :length => { :maximum => 255 }
  validates :message, :presence => true

  scope :unread, -> { where(:read => false) }
  scope :recent, -> { order(:created_at => :desc) }  # Changed from created_on to created_at

  def read?
    read == true
  end

  def mark_as_read!
    update_attribute(:read, true)
  end

  def self.create_for_issue(issue, user, action)
    return unless user && issue
    
    title = case action
            when 'created'
              l(:notification_issue_created, :id => issue.id)
            when 'updated'
              l(:notification_issue_updated, :id => issue.id)
            else
              l(:notification_issue_changed, :id => issue.id)
            end

    message = "#{issue.subject}"
    
    create!(
      :user => user,
      :issue => issue,
      :title => title,
      :message => message,
      :read => false
    )
  end

  def self.create_for_journal(journal, user)
    return unless user && journal && journal.issue
    
    title = l(:notification_issue_updated, :id => journal.issue.id)
    message = journal.notes.present? ? journal.notes : l(:notification_issue_updated_no_notes)
    
    create!(
      :user => user,
      :issue => journal.issue,
      :journal => journal,
      :title => title,
      :message => message,
      :read => false
    )
  end
end

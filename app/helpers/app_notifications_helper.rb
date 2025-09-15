module AppNotificationsHelper
  def notification_icon(notification)
    case
    when notification.issue_id.present?
      'icon-issue'
    when notification.news_id.present?
      'icon-news'
    else
      'icon-notification'
    end
  end


  def notification_url(notification)
      return notification.url if notification.url.present?
    
      if notification.issue_id.present?
        issue_path(notification.issue)
      elsif notification.news_id.present?
        news_path(notification.news)
      else
        '#'
     end
   end

  def unread_notifications_count
    return 0 unless User.current.logged?
    AppNotification.where(:user_id => User.current.id, :read => false).count
  end

  def format_notification_time(time)
    if time > 1.day.ago
      time_ago_in_words(time) + ' ' + l(:label_ago)
    else
      format_time(time)
    end
  end
end

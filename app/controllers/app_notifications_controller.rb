class AppNotificationsController < ApplicationController
  before_action :require_login
  before_action :find_notification, only: [:show, :destroy, :mark_as_read, :mark_as_unread]
  helper :app_notifications
  include AppNotificationsHelper

  def index
    @notifications = AppNotification
                       .for_user(User.current)
                       .includes(:issue, :journal)
                       .order(created_at: :desc)
                       .limit(200)
    respond_to do |format|
      format.html
      format.json { render json: @notifications }
    end
  end

  def show
    @notification.update_attribute(:read, true) unless @notification.read?
    respond_to do |format|
      format.html
      format.json { render json: @notification }
    end
  end

  def destroy
    @notification.destroy
    respond_to do |format|
      format.html { redirect_to app_notifications_path }
      format.json { head :no_content }
    end
  end

  def mark_as_read
    @notification.update_attribute(:read, true)
    respond_to do |format|
      format.json { render json: { status: 'success' } }
    end
  end

  def mark_as_unread
    @notification.update(read: false)
    respond_to do |format|
      format.json { render json: { status: 'success' } }
    end
  end

  def mark_all_as_read
    AppNotification.for_user(User.current).where(read: false).update_all(read: true)
    respond_to do |format|
      format.json { render json: { status: 'success' } }
    end
  end

  def mark_all_as_unread
    AppNotification.for_user(User.current).where(read: true).update_all(read: false)
    respond_to do |format|
      format.json { render json: { status: 'success' } }
    end
  end

  def delete_all
    AppNotification.where("user_id = :id OR recipient_id = :id", id: User.current.id).destroy_all
    respond_to do |format|
      format.json { render json: { status: 'success' } }
    end
  end

  def count
    count = AppNotification.for_user(User.current).where(read: false).count
    respond_to do |format|
      format.json { render json: { count: count } }
    end
  end

  def rfi_preferences
    redirect_to app_notifications_path unless User.current.roles.any? { |r| r.name == "Team Lead" }
  end

  def update_rfi_preferences
    redirect_to app_notifications_path unless User.current.roles.any? { |r| r.name == "Team Lead" }
    
    preferences = params[:preferences] || {}
    prefs_array = preferences.values.select { |p| p[:type].present? && p[:value].present? }
    
    User.current.rfi_notification_preferences = prefs_array
    User.current.save!
    
    redirect_to rfi_preferences_app_notifications_path, notice: 'RFI notification preferences updated successfully.'
  end

  private

  def find_notification
    @notification = AppNotification.find(params[:id])
    render_404 unless [@notification.user_id, @notification.recipient_id].include?(User.current.id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

class AppNotificationsController < ApplicationController
  before_action :require_login
  before_action :find_notification, :only => [:show, :destroy, :mark_as_read]
  
  helper :app_notifications
  include AppNotificationsHelper

  def index
    @notifications = AppNotification.where(:user_id => User.current.id)
                                   .order(:created_at => :desc)
                                   .limit(50)
    
    respond_to do |format|
      format.html
      format.json { render :json => @notifications }
    end
  end

  def show
    @notification.update_attribute(:read, true) unless @notification.read?
    
    respond_to do |format|
      format.html
      format.json { render :json => @notification }
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
      format.html { redirect_to app_notifications_path }
      format.json { render :json => { :status => 'success' } }
    end
  end

  def mark_all_as_read
    AppNotification.where(:user_id => User.current.id, :read => false)
                   .update_all(:read => true)
    
    respond_to do |format|
      format.html { redirect_to app_notifications_path }
      format.json { render :json => { :status => 'success' } }
    end
  end

  def count
    count = AppNotification.where(:user_id => User.current.id, :read => false).count
    
    respond_to do |format|
      format.json { render :json => { :count => count } }
    end
  end

  private

  def find_notification
    @notification = AppNotification.find(params[:id])
    render_404 unless @notification.user_id == User.current.id
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

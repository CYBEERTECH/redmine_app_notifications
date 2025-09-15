# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  resources :app_notifications, only: [:index, :show, :destroy] do
    member do
      patch :mark_as_read
      patch :mark_as_unread
    end
    collection do
      patch :mark_all_as_read
      patch :mark_all_as_unread
      delete :delete_all
      get :count
      get :rfi_preferences
      patch :update_rfi_preferences
    end
  end
end

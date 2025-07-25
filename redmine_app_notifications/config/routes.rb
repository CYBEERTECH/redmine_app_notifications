# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  resources :app_notifications, :only => [:index, :show, :destroy] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
      get :count
    end
  end
end

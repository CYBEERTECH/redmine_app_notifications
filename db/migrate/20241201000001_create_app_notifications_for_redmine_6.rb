class CreateAppNotificationsForRedmine6 < ActiveRecord::Migration[7.0]
  def change
    unless table_exists?(:app_notifications)
      create_table :app_notifications do |t|
        t.references :user, null: false, foreign_key: true
        t.references :recipient, null: true, foreign_key: { to_table: :users }
        t.references :issue, null: true, foreign_key: true
        t.references :journal, null: true, foreign_key: true
        t.references :news, null: true, foreign_key: true
        t.string :title, null: false, limit: 255
        t.text :message, null: false
        t.string :url, limit: 500
        t.boolean :read, default: false, null: false
        t.timestamps null: false
      end

      # Add indexes after the table is fully created
      add_index :app_notifications, [:user_id, :read]
      add_index :app_notifications, :created_at  # Changed from created_on to created_at
    end

    unless column_exists?(:users, :app_notifications_enabled)
      add_column :users, :app_notifications_enabled, :boolean, default: true
    end

    unless column_exists?(:users, :app_notification_sound_enabled)
      add_column :users, :app_notification_sound_enabled, :boolean, default: true
    end

    unless column_exists?(:users, :rfi_notification_preferences)
      add_column :users, :rfi_notification_preferences, :text
    end
  end

  def down
    drop_table :app_notifications if table_exists?(:app_notifications)
    remove_column :users, :app_notifications_enabled if column_exists?(:users, :app_notifications_enabled)
    remove_column :users, :app_notification_sound_enabled if column_exists?(:users, :app_notification_sound_enabled)
  end
end

class AddTitleToChatSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_sessions, :title, :string
  end
end

class CreateChatSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, default: 'active'
      t.json :conversation_state
      t.json :extracted_data
      t.datetime :completed_at
      t.timestamps
    end

    add_index :chat_sessions, [ :user_id, :status ]
    add_index :chat_sessions, :completed_at
  end
end

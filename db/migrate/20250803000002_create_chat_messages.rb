class CreateChatMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_messages do |t|
      t.references :chat_session, null: false, foreign_key: true
      t.string :role, null: false # 'user' or 'assistant'
      t.text :content, null: false
      t.string :audio_file_path
      t.json :metadata
      t.timestamps
    end

    add_index :chat_messages, [ :chat_session_id, :created_at ]
    add_index :chat_messages, :role
  end
end

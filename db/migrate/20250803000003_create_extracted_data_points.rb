class CreateExtractedDataPoints < ActiveRecord::Migration[7.0]
  def change
    create_table :extracted_data_points do |t|
      t.references :chat_session, null: false, foreign_key: true
      t.string :category, null: false
      t.string :data_type
      t.text :value
      t.json :context
      t.float :confidence_score
      t.timestamps
    end

    add_index :extracted_data_points, [ :chat_session_id, :category ]
    add_index :extracted_data_points, :data_type
  end
end

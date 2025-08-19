class CreateUserResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :user_responses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :life_category, null: false, foreign_key: true
      t.text :raw_response
      t.text :analysis_data
      t.integer :status

      t.timestamps
    end
  end
end

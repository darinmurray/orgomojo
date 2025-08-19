class CreateLifeGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :life_goals do |t|
      t.references :user_response, null: false, foreign_key: true
      t.references :life_category, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :timeframe
      t.text :success_metric
      t.text :addresses_challenge
      t.integer :goal_type
      t.integer :status

      t.timestamps
    end
  end
end

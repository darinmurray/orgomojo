class CreateSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :settings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :gender, default: "none"
      t.string :tone_1, default: "positive"
      t.string :tone_2, default: "aggressive"
      t.string :timespan, default: "within 3 months"
      t.integer :pie_objective_length, default: 15
      t.integer :slice_objective_length, default: 15
      t.integer :slice_element_length, default: 10
      t.integer :element_objective_length, default: 20
      t.integer :task_length, default: 10
      t.integer :task_outcome_length, default: 8

      t.timestamps
    end
  end
end

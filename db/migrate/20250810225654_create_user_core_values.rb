class CreateUserCoreValues < ActiveRecord::Migration[8.0]
  def change
    create_table :user_core_values do |t|
      t.references :user, null: false, foreign_key: true
      t.references :core_value, null: false, foreign_key: true
      t.integer :importance_level, default: 5, comment: "Scale of 1-10 indicating how important this value is to the user"
      t.text :personal_notes, comment: "User's personal notes about how this value applies to their life"

      t.timestamps
    end

    # Ensure a user can't have the same core value twice
    add_index :user_core_values, [ :user_id, :core_value_id ], unique: true
  end
end

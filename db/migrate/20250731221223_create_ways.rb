class CreateWays < ActiveRecord::Migration[8.0]
  def change
    create_table :ways do |t|
      t.references :user, null: false, foreign_key: true
      t.references :six_human_need, null: false, foreign_key: true
      t.text :description, null: false

      t.timestamps
    end

    # Add composite index for efficient querying
    add_index :ways, [ :user_id, :six_human_need_id ]
  end
end

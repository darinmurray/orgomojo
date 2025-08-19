class CreateSixHumanNeeds < ActiveRecord::Migration[7.0]
  def change
    create_table :six_human_needs do |t|
      t.string :name, null: false, limit: 100
      t.text :description, null: false
      t.integer :order_position, null: false

      t.timestamps
    end

    add_index :six_human_needs, :name, unique: true
    add_index :six_human_needs, :order_position, unique: true
  end
end

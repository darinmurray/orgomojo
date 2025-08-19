class CreateElements < ActiveRecord::Migration[8.0]
  def change
    create_table :elements do |t|
      t.integer :slice_id, null: false
      t.string :name
      t.boolean :completed, default: false

      t.timestamps
    end
    
    add_foreign_key :elements, :slices
    add_index :elements, :slice_id
  end
end

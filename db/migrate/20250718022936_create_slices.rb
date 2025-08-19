class CreateSlices < ActiveRecord::Migration[8.0]
  def change
    create_table :slices do |t|
      t.string :name
      t.integer :percentage
      t.string :color
      t.references :pie, null: false, foreign_key: true

      t.timestamps
    end
  end
end

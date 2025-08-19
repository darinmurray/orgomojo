class AddObjectiveToSlices < ActiveRecord::Migration[8.0]
  def change
    add_column :slices, :objective, :text
  end
end

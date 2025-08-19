class AddObjectiveToElements < ActiveRecord::Migration[8.0]
  def change
    add_column :elements, :objective, :text
  end
end

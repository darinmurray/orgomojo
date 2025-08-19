class AddCadenceToElements < ActiveRecord::Migration[8.0]
  def change
    add_column :elements, :cadence, :string
  end
end

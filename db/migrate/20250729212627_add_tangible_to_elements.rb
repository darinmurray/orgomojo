class AddTangibleToElements < ActiveRecord::Migration[8.0]
  def change
    add_column :elements, :tangible, :boolean
  end
end

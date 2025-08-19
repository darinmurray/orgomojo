class AddColumnsToElements < ActiveRecord::Migration[6.0]
  def change
    add_column :elements, :priority, :integer
    add_column :elements, :time_needed, :integer
    add_column :elements, :time_scale, :string
    add_column :elements, :deadline, :datetime
  end
end

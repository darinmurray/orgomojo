class AddPrimaryWheelToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :primary_wheel, :integer, null: true
    add_foreign_key :settings, :pies, column: :primary_wheel
    add_index :settings, :primary_wheel
  end
end

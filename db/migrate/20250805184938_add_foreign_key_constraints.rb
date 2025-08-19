class AddForeignKeyConstraints < ActiveRecord::Migration[8.0]
  def change
    # Add foreign key constraint for slices -> pies with cascade delete
    unless foreign_key_exists?(:slices, :pies)
      add_foreign_key :slices, :pies, on_delete: :cascade
    end

    # Add foreign key constraint for elements -> slices with cascade delete
    unless foreign_key_exists?(:elements, :slices)
      add_foreign_key :elements, :slices, on_delete: :cascade
    end
  end
end

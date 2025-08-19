class AddOutcomeTypeToElements < ActiveRecord::Migration[8.0]
  def change
    add_column :elements, :outcome_type, :string
  end
end

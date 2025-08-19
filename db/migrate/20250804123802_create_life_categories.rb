class CreateLifeCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :life_categories do |t|
      t.string :name
      t.text :prompt_template
      t.text :description

      t.timestamps
    end
  end
end

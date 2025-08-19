class CreatePies < ActiveRecord::Migration[8.0]
  def change
    create_table :pies do |t|
      t.string :name

      t.timestamps
    end
  end
end

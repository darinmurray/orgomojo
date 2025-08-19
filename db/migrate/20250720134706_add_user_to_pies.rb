class AddUserToPies < ActiveRecord::Migration[8.0]
  def change
    add_reference :pies, :user, null: true, foreign_key: true
  end
end

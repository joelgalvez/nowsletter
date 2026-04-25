class AddToLog < ActiveRecord::Migration[8.0]
  def change
    add_reference :logs, :letter, null: true, foreign_key: true
    add_reference :logs, :event, null: true, foreign_key: true
  end
end

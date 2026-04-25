class AddTextToLog < ActiveRecord::Migration[8.0]
  def change
    add_column :logs, :text, :text
  end
end

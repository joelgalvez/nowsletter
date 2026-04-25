class CreateAvailableModels < ActiveRecord::Migration[8.1]
  def change
    create_table :available_models do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :available_models, :name, unique: true
  end
end

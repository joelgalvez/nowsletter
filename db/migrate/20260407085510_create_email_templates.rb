class CreateEmailTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :email_templates do |t|
      t.string :key
      t.text :text

      t.timestamps
    end
  end
end

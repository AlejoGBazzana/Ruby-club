class CreateDeportistas < ActiveRecord::Migration[8.1]
  def change
    create_table :deportistas do |t|
      t.integer :edad, null: false
      t.references :socio, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end

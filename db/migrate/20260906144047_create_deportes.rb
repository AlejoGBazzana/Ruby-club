class CreateDeportes < ActiveRecord::Migration[8.1]
  def change
    create_table :deportes do |t|
      t.string :nombre, null: false

      t.timestamps
    end

    add_index :deportes, :nombre, unique: true
  end
end

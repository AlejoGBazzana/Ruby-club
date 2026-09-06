class CreateSocios < ActiveRecord::Migration[8.1]
  def change
    create_table :socios do |t|
      t.string :nombre, null: false
      t.string :apellido, null: false
      t.string :email, null: false
      t.date :fecha_inscripcion, null: false

      t.timestamps
    end

    add_index :socios, :email, unique: true
  end
end

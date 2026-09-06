class CreateActividades < ActiveRecord::Migration[8.1]
  def change
    create_table :actividades do |t|
      t.string :nombre, null: false
      t.date :fecha, null: false
      t.time :horario, null: false
      t.integer :cupo, null: false
      t.references :deporte, null: false, foreign_key: true

      t.timestamps
    end
  end
end

class CreateInscripciones < ActiveRecord::Migration[8.1]
  def change
    create_table :inscripciones do |t|
      t.references :deportista, null: false, foreign_key: { to_table: :deportistas }
      t.references :actividad, null: false, foreign_key: { to_table: :actividades }
      t.date :fecha_inscripcion, null: false
      t.string :estado, null: false, default: "pendiente"

      t.timestamps
    end

    add_index :inscripciones, [:deportista_id, :actividad_id],
              unique: true,
              where: "estado != 'cancelada'",
              name: "idx_inscripciones_activas_unicas"
  end
end

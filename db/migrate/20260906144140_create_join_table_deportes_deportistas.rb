class CreateJoinTableDeportesDeportistas < ActiveRecord::Migration[8.1]
  def change
    create_table :deportes_deportistas, id: false do |t|
      t.references :deporte, null: false, foreign_key: { to_table: :deportes }
      t.references :deportista, null: false, foreign_key: { to_table: :deportistas }
    end

    add_index :deportes_deportistas, [:deporte_id, :deportista_id], unique: true
    add_index :deportes_deportistas, [:deportista_id, :deporte_id]
  end
end

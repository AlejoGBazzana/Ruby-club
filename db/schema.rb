# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_06_144140) do
  create_table "actividades", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "cupo", null: false
    t.integer "deporte_id", null: false
    t.date "fecha", null: false
    t.time "horario", null: false
    t.string "nombre", null: false
    t.datetime "updated_at", null: false
    t.index ["deporte_id"], name: "index_actividades_on_deporte_id"
  end

  create_table "deportes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nombre", null: false
    t.datetime "updated_at", null: false
    t.index ["nombre"], name: "index_deportes_on_nombre", unique: true
  end

  create_table "deportes_deportistas", id: false, force: :cascade do |t|
    t.integer "deporte_id", null: false
    t.integer "deportista_id", null: false
    t.index ["deporte_id", "deportista_id"], name: "index_deportes_deportistas_on_deporte_id_and_deportista_id", unique: true
    t.index ["deporte_id"], name: "index_deportes_deportistas_on_deporte_id"
    t.index ["deportista_id", "deporte_id"], name: "index_deportes_deportistas_on_deportista_id_and_deporte_id"
    t.index ["deportista_id"], name: "index_deportes_deportistas_on_deportista_id"
  end

  create_table "deportistas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "edad", null: false
    t.integer "socio_id", null: false
    t.datetime "updated_at", null: false
    t.index ["socio_id"], name: "index_deportistas_on_socio_id", unique: true
  end

  create_table "inscripciones", force: :cascade do |t|
    t.integer "actividad_id", null: false
    t.datetime "created_at", null: false
    t.integer "deportista_id", null: false
    t.string "estado", default: "pendiente", null: false
    t.date "fecha_inscripcion", null: false
    t.datetime "updated_at", null: false
    t.index ["actividad_id"], name: "index_inscripciones_on_actividad_id"
    t.index ["deportista_id", "actividad_id"], name: "idx_inscripciones_activas_unicas", unique: true, where: "estado != 'cancelada'"
    t.index ["deportista_id"], name: "index_inscripciones_on_deportista_id"
  end

  create_table "socios", force: :cascade do |t|
    t.string "apellido", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.date "fecha_inscripcion", null: false
    t.string "nombre", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_socios_on_email", unique: true
  end

  add_foreign_key "actividades", "deportes"
  add_foreign_key "deportes_deportistas", "deportes"
  add_foreign_key "deportes_deportistas", "deportistas"
  add_foreign_key "deportistas", "socios"
  add_foreign_key "inscripciones", "actividades"
  add_foreign_key "inscripciones", "deportistas"
end

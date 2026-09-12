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

ActiveRecord::Schema[8.1].define(version: 2026_09_11_120000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "users", force: :cascade do |t|
    t.string "api_token_digest"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "user", null: false
    t.integer "socio_id"
    t.datetime "updated_at", null: false
    t.index ["api_token_digest"], name: "index_users_on_api_token_digest", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["socio_id"], name: "index_users_on_socio_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "actividades", "deportes"
  add_foreign_key "deportes_deportistas", "deportes"
  add_foreign_key "deportes_deportistas", "deportistas"
  add_foreign_key "deportistas", "socios"
  add_foreign_key "inscripciones", "actividades"
  add_foreign_key "inscripciones", "deportistas"
  add_foreign_key "users", "socios"
end

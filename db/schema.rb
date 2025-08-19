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

ActiveRecord::Schema[8.0].define(version: 2025_08_10_225654) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "chat_session_id", null: false
    t.string "role", null: false
    t.text "content", null: false
    t.string "audio_file_path"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_session_id", "created_at"], name: "index_chat_messages_on_chat_session_id_and_created_at"
    t.index ["chat_session_id"], name: "index_chat_messages_on_chat_session_id"
    t.index ["role"], name: "index_chat_messages_on_role"
  end

  create_table "chat_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "status", default: "active"
    t.json "conversation_state"
    t.json "extracted_data"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["completed_at"], name: "index_chat_sessions_on_completed_at"
    t.index ["user_id", "status"], name: "index_chat_sessions_on_user_id_and_status"
    t.index ["user_id"], name: "index_chat_sessions_on_user_id"
  end

  create_table "core_values", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "examples", default: [], array: true
  end

  create_table "elements", force: :cascade do |t|
    t.integer "slice_id", null: false
    t.string "name"
    t.boolean "completed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "objective"
    t.integer "priority"
    t.integer "time_needed"
    t.string "time_scale"
    t.datetime "deadline", precision: nil
    t.boolean "tangible"
    t.string "outcome_type"
    t.string "cadence"
    t.index ["slice_id"], name: "index_elements_on_slice_id"
  end

  create_table "extracted_data_points", force: :cascade do |t|
    t.bigint "chat_session_id", null: false
    t.string "category", null: false
    t.string "data_type"
    t.text "value"
    t.json "context"
    t.float "confidence_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_session_id", "category"], name: "index_extracted_data_points_on_chat_session_id_and_category"
    t.index ["chat_session_id"], name: "index_extracted_data_points_on_chat_session_id"
    t.index ["data_type"], name: "index_extracted_data_points_on_data_type"
  end

  create_table "life_categories", force: :cascade do |t|
    t.string "name"
    t.text "prompt_template"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "life_goals", force: :cascade do |t|
    t.bigint "user_response_id", null: false
    t.bigint "life_category_id", null: false
    t.string "title"
    t.text "description"
    t.string "timeframe"
    t.text "success_metric"
    t.text "addresses_challenge"
    t.integer "goal_type"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["life_category_id"], name: "index_life_goals_on_life_category_id"
    t.index ["user_response_id"], name: "index_life_goals_on_user_response_id"
  end

  create_table "pies", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_pies_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "gender", default: "none"
    t.string "tone_1", default: "positive"
    t.string "tone_2", default: "aggressive"
    t.string "timespan", default: "within 3 months"
    t.integer "pie_objective_length", default: 15
    t.integer "slice_objective_length", default: 15
    t.integer "slice_element_length", default: 10
    t.integer "element_objective_length", default: 20
    t.integer "task_length", default: 10
    t.integer "task_outcome_length", default: 8
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_settings_on_user_id"
  end

  create_table "six_human_needs", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.text "description", null: false
    t.integer "order_position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_six_human_needs_on_name", unique: true
    t.index ["order_position"], name: "index_six_human_needs_on_order_position", unique: true
  end

  create_table "slices", force: :cascade do |t|
    t.string "name"
    t.integer "percentage"
    t.string "color"
    t.bigint "pie_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "objective"
    t.index ["pie_id"], name: "index_slices_on_pie_id"
  end

  create_table "user_core_values", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "core_value_id", null: false
    t.integer "importance_level", default: 5, comment: "Scale of 1-10 indicating how important this value is to the user"
    t.text "personal_notes", comment: "User's personal notes about how this value applies to their life"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["core_value_id"], name: "index_user_core_values_on_core_value_id"
    t.index ["user_id", "core_value_id"], name: "index_user_core_values_on_user_id_and_core_value_id", unique: true
    t.index ["user_id"], name: "index_user_core_values_on_user_id"
  end

  create_table "user_responses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "life_category_id", null: false
    t.text "raw_response"
    t.text "analysis_data"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["life_category_id"], name: "index_user_responses_on_life_category_id"
    t.index ["user_id"], name: "index_user_responses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.string "firstname"
    t.string "lastname"
    t.string "photo"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "ways", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "six_human_need_id", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["six_human_need_id"], name: "index_ways_on_six_human_need_id"
    t.index ["user_id", "six_human_need_id"], name: "index_ways_on_user_id_and_six_human_need_id"
    t.index ["user_id"], name: "index_ways_on_user_id"
  end

  add_foreign_key "chat_messages", "chat_sessions"
  add_foreign_key "chat_sessions", "users"
  add_foreign_key "elements", "slices"
  add_foreign_key "extracted_data_points", "chat_sessions"
  add_foreign_key "life_goals", "life_categories"
  add_foreign_key "life_goals", "user_responses"
  add_foreign_key "pies", "users"
  add_foreign_key "settings", "users"
  add_foreign_key "slices", "pies"
  add_foreign_key "user_core_values", "core_values"
  add_foreign_key "user_core_values", "users"
  add_foreign_key "user_responses", "life_categories"
  add_foreign_key "user_responses", "users"
  add_foreign_key "ways", "six_human_needs"
  add_foreign_key "ways", "users"
end

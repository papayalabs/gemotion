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

ActiveRecord::Schema[7.1].define(version: 2024_05_11_102609) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "video_destinataires", force: :cascade do |t|
    t.integer "genre"
    t.integer "age"
    t.string "name"
    t.text "more_info"
    t.bigint "video_id", null: false
    t.text "specific_request"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["video_id"], name: "index_video_destinataires_on_video_id"
  end

  create_table "videos", force: :cascade do |t|
    t.integer "video_type", null: false
    t.string "stop_at", default: "start", null: false
    t.integer "occasion"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "video_destinataires", "videos"
end

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

ActiveRecord::Schema[7.1].define(version: 2025_05_04_154933) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "board_logs", force: :cascade do |t|
    t.integer "board_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "connected", default: false, null: false
    t.integer "signal_strength"
    t.string "ssid"
    t.index ["created_at"], name: "index_board_logs_on_created_at"
    t.index ["updated_at"], name: "index_board_logs_on_updated_at"
  end

  create_table "boards", force: :cascade do |t|
    t.string "ip"
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "connected_at", precision: nil
    t.string "board_type"
    t.string "ssid"
    t.integer "signal_strength"
    t.integer "version"
    t.integer "slave_address"
    t.integer "data_read_interval"
    t.integer "days_to_preserve_logs"
    t.index ["board_type"], name: "index_boards_on_board_type"
    t.index ["connected_at"], name: "index_boards_on_connected_at"
    t.index ["data_read_interval"], name: "index_boards_on_data_read_interval"
    t.index ["days_to_preserve_logs"], name: "index_boards_on_days_to_preserve_logs"
    t.index ["ip"], name: "index_boards_on_ip"
    t.index ["name"], name: "index_boards_on_name"
    t.index ["version"], name: "index_boards_on_version"
  end

  create_table "device_logs", force: :cascade do |t|
    t.integer "device_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "value_integer"
    t.boolean "value_boolean"
    t.string "value_string"
    t.decimal "value_decimal", precision: 6, scale: 2
    t.index ["created_at"], name: "index_device_logs_on_created_at"
    t.index ["device_id"], name: "index_device_logs_on_device_id"
    t.index ["updated_at"], name: "index_device_logs_on_updated_at"
  end

  create_table "devices", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "device_type"
    t.integer "pin"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "board_id"
    t.datetime "last_change", precision: nil
    t.string "type"
    t.integer "value_integer"
    t.boolean "value_boolean"
    t.string "value_string"
    t.decimal "value_decimal", precision: 6, scale: 2
    t.boolean "inverted", default: false, null: false
    t.integer "poll"
    t.integer "holding_register_address"
    t.integer "scale"
    t.string "unit"
    t.string "modbus_data_type"
    t.string "compression_type"
    t.string "compression_timespan"
    t.integer "compression_backlog"
    t.datetime "compression_last_run_at", precision: nil
    t.integer "days_to_preserve_logs"
    t.boolean "log_enabled", default: true, null: false
    t.boolean "virtual_writable", default: false, null: false
    t.index ["board_id"], name: "index_devices_on_board_id"
    t.index ["compression_last_run_at"], name: "index_devices_on_compression_last_run_at"
    t.index ["days_to_preserve_logs"], name: "index_devices_on_days_to_preserve_logs"
    t.index ["device_type"], name: "index_devices_on_device_type"
    t.index ["last_change"], name: "index_devices_on_last_change"
    t.index ["log_enabled"], name: "index_devices_on_log_enabled"
    t.index ["name"], name: "index_devices_on_name"
    t.index ["pin"], name: "index_devices_on_pin"
    t.index ["type"], name: "index_devices_on_type"
    t.index ["virtual_writable"], name: "index_devices_on_virtual_writable"
  end

  create_table "panels", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "row", default: 12
    t.integer "column", default: 12
    t.boolean "public_access", default: false, null: false
    t.index ["created_at"], name: "index_panels_on_created_at"
    t.index ["name"], name: "index_panels_on_name"
  end

  create_table "programs", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "program_type"
    t.text "code"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "repeat_every"
    t.text "last_error_message"
    t.datetime "last_run", precision: nil
    t.text "storage"
    t.boolean "enabled", default: false, null: false
    t.integer "runtime"
    t.datetime "last_error_at", precision: nil
    t.text "compiled_code"
    t.text "output"
    t.index ["created_at"], name: "index_programs_on_created_at"
    t.index ["enabled"], name: "index_programs_on_enabled"
    t.index ["last_error_at"], name: "index_programs_on_last_error_at"
    t.index ["last_run"], name: "index_programs_on_last_run"
    t.index ["program_type"], name: "index_programs_on_program_type"
    t.index ["updated_at"], name: "index_programs_on_updated_at"
  end

  create_table "programs_devices", id: :serial, force: :cascade do |t|
    t.integer "program_id"
    t.integer "device_id"
    t.string "variable_name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "trigger", default: false, null: false
    t.index ["device_id"], name: "index_programs_devices_on_device_id"
    t.index ["program_id"], name: "index_programs_devices_on_program_id"
    t.index ["trigger"], name: "index_programs_devices_on_trigger"
    t.index ["variable_name"], name: "index_programs_devices_on_variable_name"
  end

  create_table "widgets", force: :cascade do |t|
    t.integer "panel_id", null: false
    t.string "widget_type"
    t.integer "device_id"
    t.integer "program_id"
    t.integer "x"
    t.integer "y"
    t.integer "w"
    t.integer "h"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color_1"
    t.string "color_2"
    t.string "icon"
    t.string "name"
    t.boolean "show_updated", default: false, null: false
    t.boolean "show_label", default: true, null: false
    t.index ["created_at"], name: "index_widgets_on_created_at"
    t.index ["device_id"], name: "index_widgets_on_device_id"
    t.index ["name"], name: "index_widgets_on_name"
    t.index ["panel_id"], name: "index_widgets_on_panel_id"
    t.index ["program_id"], name: "index_widgets_on_program_id"
    t.index ["show_label"], name: "index_widgets_on_show_label"
    t.index ["show_updated"], name: "index_widgets_on_show_updated"
    t.index ["updated_at"], name: "index_widgets_on_updated_at"
  end

end

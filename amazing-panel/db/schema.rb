# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101020161026) do

  create_table "device_kinds", :force => true do |t|
    t.integer "inventory_id",               :null => false
    t.string  "bus",          :limit => 16
    t.integer "vendor",                     :null => false
    t.integer "device",                     :null => false
  end

  create_table "device_ouis", :id => false, :force => true do |t|
    t.string  "oui",            :limit => 8, :null => false
    t.integer "device_kind_id",              :null => false
    t.integer "inventory_id"
  end

  create_table "device_tags", :id => false, :force => true do |t|
    t.string  "tag",            :limit => 64, :null => false
    t.integer "device_kind_id",               :null => false
    t.integer "inventory_id"
  end

  create_table "devices", :force => true do |t|
    t.integer "device_kind_id",               :null => false
    t.integer "motherboard_id"
    t.integer "inventory_id",                 :null => false
    t.string  "address",        :limit => 18, :null => false
    t.string  "mac",            :limit => 17
    t.string  "canonical_name", :limit => 64
  end

  create_table "inventories", :force => true do |t|
    t.timestamp "opened", :null => false
    t.timestamp "closed", :null => false
  end

  create_table "locations", :force => true do |t|
    t.string  "name",       :limit => 64
    t.integer "x",                        :default => 0, :null => false
    t.integer "y",                        :default => 0, :null => false
    t.integer "z",                        :default => 0, :null => false
    t.float   "latitude"
    t.float   "longitude"
    t.float   "elevation"
    t.integer "testbed_id",                              :null => false
  end

  create_table "motherboards", :force => true do |t|
    t.integer "inventory_id",                                  :null => false
    t.string  "mfr_sn",       :limit => 128
    t.string  "cpu_type",     :limit => 64
    t.integer "cpu_n"
    t.float   "cpu_hz"
    t.string  "hd_sn",        :limit => 64
    t.integer "hd_size"
    t.boolean "hd_status",                   :default => true
    t.integer "memory"
  end

  add_index "motherboards", ["mfr_sn"], :name => "mfr_sn", :unique => true

  create_table "nodes", :force => true do |t|
    t.string  "control_ip",     :limit => 15
    t.string  "control_mac",    :limit => 17
    t.string  "hostname",       :limit => 64
    t.string  "hrn",            :limit => 128
    t.integer "inventory_id",                                          :null => false
    t.string  "chassis_sn",     :limit => 64
    t.integer "motherboard_id",                                        :null => false
    t.integer "location_id"
    t.integer "pxeimage_id"
    t.string  "disk",           :limit => 32,  :default => "/dev/hdd"
  end

  add_index "nodes", ["location_id"], :name => "location_id", :unique => true

  create_table "pxeimages", :id => false, :force => true do |t|
    t.integer "id"
    t.string  "image_name",        :limit => 64
    t.string  "short_description", :limit => 128
  end

  create_table "testbeds", :force => true do |t|
    t.string "name", :limit => 128, :null => false
  end

  add_index "testbeds", ["name"], :name => "node_domain", :unique => true

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "",    :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "",    :null => false
    t.string   "password_salt",                       :default => "",    :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                               :default => false
    t.boolean  "activated",                           :default => false
    t.string   "username"
    t.string   "intention"
    t.string   "name"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end

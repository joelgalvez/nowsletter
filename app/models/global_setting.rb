class GlobalSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.get(key, default = nil)
    setting = find_by(key: key)
    setting ? setting.value : default
  end

  def self.set(key, value)
    setting = find_or_initialize_by(key: key)
    setting.value = value.to_s
    setting.save!
  end

  def self.test_mode?
    get("test_mode", "false") == "true"
  end

  def self.test_mode=(value)
    set("test_mode", value ? "true" : "false")
  end

  def self.keep_server_up?
    get("keep_server_up", "false") == "true"
  end

  def self.keep_server_up=(value)
    set("keep_server_up", value ? "true" : "false")
  end
end

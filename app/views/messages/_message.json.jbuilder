json.extract! message, :id, :text, :can_close, :created_at, :updated_at
json.url message_url(message, format: :json)

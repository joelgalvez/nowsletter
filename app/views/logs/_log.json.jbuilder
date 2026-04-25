json.extract! log, :id, :title, :venue_id, :role, :severity, :created_at, :updated_at
json.url log_url(log, format: :json)

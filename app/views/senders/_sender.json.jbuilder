json.extract! sender, :id, :email, :venue_id, :created_at, :updated_at
json.url sender_url(sender, format: :json)

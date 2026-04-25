json.extract! venue, :id, :title, :website, :created_at, :updated_at
json.url venue_url(venue, format: :json)

json.extract! letter, :id, :from, :body, :uid, :subject, :json, :sent_date, :created_at, :updated_at
json.url letter_url(letter, format: :json)

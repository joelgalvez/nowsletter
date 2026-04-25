# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*" # Change this to specific domains in production

    resource "/api/*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ "Authorization" ],
      max_age: 600
  end

  allow do
    origins "*"
    resource "/health",
      headers: :any,
      methods: [ :get, :options, :head ]
  end
end

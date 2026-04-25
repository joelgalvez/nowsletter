# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create admin user
admin_email = ENV["INITIAL_ADMIN_EMAIL"]
User.find_or_create_by!(email_address: admin_email) do |user|
  user.password = SecureRandom.hex(16)
  user.role = 'admin'
  puts "Created admin user: #{admin_email}"
end

# Create parser user
parser_email    = ENV["PARSER_EMAIL"]
parser_password = ENV["PARSER_PASSWORD"] || SecureRandom.hex(16)
if parser_email.present?
  User.find_or_create_by!(email_address: parser_email) do |user|
    user.password = parser_password
    user.role = 'parser'
    puts "Created parser user: #{parser_email}"
  end
end

# Create default prompt
Prompt.find_or_create_by!(title: "default") do |prompt|
  prompt.text = <<~TEXT
      <INP>
        Extract all events from the following text. Overlapping or duplicate events is fine, better too many than to few.
        This newsletter was sent on \#{sent_date}, calculate the dates relative to this date.
        Don't mistake someones birthplace with the location of the event.
        Deduce the country_code from the city. Only list a city if it exists. Strictly translate city to English if it is not in English.
        Choose img that comes before the title, relative to the title.
        Title needs to contain a string, put "(no title)" if nothing is found.
        If "until" is mentioned set start_date_time to \#{sent_date} and end_date_time to the mentioned date.

        <TEXT>
          {{{text}}}
        </TEXT>

        and return as json in format:
          {
            "events": [
              {
                  "start_date_time" (YYYY-MM-DD HH:MM),
                  "end_date_time" (YYYY-MM-DD HH:MM),
                  "img" (string),
                  "title" (string),
                  "city" (string, city name translated to English),
                  "country_code" (2 character ISO 3166),
                  "tags": (max 3 comma separated tags in English),
                  "address": (string),
              }
            ]
          }
      </INP>
  TEXT
  puts "Created default prompt"
end


# Create default email template
EmailTemplate.find_or_create_by!(key: "default") do |template|
  template.text = "Hello, we've added the events from your latest newsletter. You can change things as you want here:"
  puts "Created default email template"
end


# Create lists
List.find_or_create_by!(title: 'Public') do |list|
  puts "Created list: Public"
end

List.find_or_create_by!(title: 'really') do |list|
  puts "Created list: really"
end

# Create default model setting
Setting.find_or_create_by!(name: "model") do |setting|
  setting.value = AvailableModel.order(:name).first&.name || ""
  setting.description = "The LLM model to use for parsing"
  puts "Created model setting"
end

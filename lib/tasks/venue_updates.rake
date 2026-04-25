namespace :venues do
  desc "Set all venues to have in=true"
  task set_all_in_true: :environment do
    puts "Updating all venues to have in=true..."
    count = Venue.update_all(in: true)
    puts "Updated #{count} venues successfully."
  end
end

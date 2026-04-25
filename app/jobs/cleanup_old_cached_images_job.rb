class CleanupOldCachedImagesJob < ApplicationJob
  queue_as :default

  def perform(dry_run: false)
    events_cleaned_count = 0
    events_failed_count = 0
    letters_cleaned_count = 0
    letters_failed_count = 0
    files_deleted_count = 0
    files_failed_count = 0

    mode = dry_run ? "DRY RUN" : "LIVE"
    cutoff_date = 6.months.ago

    log "========== Starting Old Cached Images Cleanup (#{mode}) =========="
    log "Cleaning up images from events that passed before #{cutoff_date.strftime('%Y-%m-%d')}"

    # Find events that passed more than 3 months ago
    old_events = Event.where("COALESCE(end_date, start_date) < ?", cutoff_date)
                      .where.not(lead_image_cached: [ nil, "" ])

    total_events = old_events.count
    log "Found #{total_events} old events with cached lead images"

    old_events.find_each.with_index do |event, index|
      log "Processing event #{event.id} (#{index + 1}/#{total_events})"

      begin
        cached_path = event.lead_image_cached

        # Delete the cached image file from disk
        if cached_path.present? && cached_path.start_with?("/cached_images/")
          local_path = Rails.root.join("public", cached_path.delete_prefix("/"))

          if File.exist?(local_path)
            if dry_run
              log "  Event #{event.id}: [DRY RUN] Would delete #{local_path}"
            else
              File.delete(local_path)
              files_deleted_count += 1
              log "  Event #{event.id}: ✓ Deleted file #{cached_path}"
            end
          else
            log "  Event #{event.id}: File not found (#{cached_path}), will clear DB anyway"
          end

          # Delete thumbnail if it exists
          thumbnail_path = event.display_lead_image_thumbnail(600, 400)
          if thumbnail_path && thumbnail_path.start_with?("/cached_images/")
            thumb_local_path = Rails.root.join("public", thumbnail_path.delete_prefix("/"))
            if File.exist?(thumb_local_path)
              if dry_run
                log "  Event #{event.id}: [DRY RUN] Would delete thumbnail #{thumb_local_path}"
              else
                File.delete(thumb_local_path)
                files_deleted_count += 1
                log "  Event #{event.id}: ✓ Deleted thumbnail #{thumbnail_path}"
              end
            end
          end

          # Delete the event's directory if it's empty
          event_dir = Rails.root.join("public", "cached_images", "events", event.id.to_s)
          if Dir.exist?(event_dir)
            if dry_run
              log "  Event #{event.id}: [DRY RUN] Would check and delete empty directory"
            else
              # Delete empty subdirectories first (like thumbnails/)
              Dir.glob(event_dir.join("*")).each do |subdir|
                if Dir.exist?(subdir) && Dir.empty?(subdir)
                  Dir.delete(subdir)
                  log "  Event #{event.id}: ✓ Deleted empty subdirectory #{File.basename(subdir)}"
                end
              end

              # Delete the main event directory if now empty
              if Dir.empty?(event_dir)
                Dir.delete(event_dir)
                log "  Event #{event.id}: ✓ Deleted empty directory events/#{event.id}"
              end
            end
          end
        end

        # Clear the database field
        unless dry_run
          event.update_column(:lead_image_cached, nil)
        end

        events_cleaned_count += 1
        log "  Event #{event.id}: ✓ Cleared lead_image_cached"
      rescue => e
        events_failed_count += 1
        log "  Event #{event.id}: ✗ Error - #{e.message}"
        log "    #{e.backtrace.first}"
      end
    end

    # Find letters with events that passed more than 3 months ago
    log "\nSearching for letters with old events..."

    old_letters = Letter.joins(:events)
                        .where("COALESCE(events.end_date, events.start_date) < ?", cutoff_date)
                        .where.not(body_cached: [ nil, "" ])
                        .distinct

    total_letters = old_letters.count
    log "Found #{total_letters} letters with cached images from old events"

    old_letters.find_each.with_index do |letter, index|
      log "Processing letter #{letter.id} (#{index + 1}/#{total_letters})"

      begin
        # Extract image URLs from body_cached HTML
        if letter.body_cached.present?
          image_urls = letter.body_cached.scan(/src=["']([^"']*\/cached_images\/[^"']*)["']/i).flatten

          if image_urls.any?
            log "  Letter #{letter.id}: Found #{image_urls.length} cached images"

            image_urls.each do |img_url|
              # Clean up the URL (remove any leading /)
              clean_url = img_url.start_with?("/") ? img_url : "/#{img_url}"
              local_path = Rails.root.join("public", clean_url.delete_prefix("/"))

              if File.exist?(local_path)
                if dry_run
                  log "    [DRY RUN] Would delete #{clean_url}"
                else
                  File.delete(local_path)
                  files_deleted_count += 1
                  log "    ✓ Deleted #{clean_url}"
                end
              else
                log "    File not found: #{clean_url}"
              end
            end
          end

          # Clear body_cached from database
          unless dry_run
            letter.update_column(:body_cached, nil)
          end

          letters_cleaned_count += 1
          log "  Letter #{letter.id}: ✓ Cleared body_cached"

          # Delete the letter's directory if it's empty
          letter_dir = Rails.root.join("public", "cached_images", "letters", letter.id.to_s)
          if Dir.exist?(letter_dir)
            if dry_run
              log "  Letter #{letter.id}: [DRY RUN] Would check and delete empty directory"
            else
              # Delete the directory if it's empty
              if Dir.empty?(letter_dir)
                Dir.delete(letter_dir)
                log "  Letter #{letter.id}: ✓ Deleted empty directory letters/#{letter.id}"
              else
                log "  Letter #{letter.id}: Directory not empty, keeping it"
              end
            end
          end
        end
      rescue => e
        letters_failed_count += 1
        log "  Letter #{letter.id}: ✗ Error - #{e.message}"
        log "    #{e.backtrace.first}"
      end
    end

    # Create a log entry in the database
    unless dry_run
      Log.create!(
        title: "Cleaned up old cached images: #{events_cleaned_count} events, #{letters_cleaned_count} letters, #{files_deleted_count} files deleted",
        severity: "normal",
        role: "admin"
      )
    end

    log "========== Cleanup Complete =========="
    log "Events: #{events_cleaned_count} cleaned, #{events_failed_count} failed"
    log "Letters: #{letters_cleaned_count} cleaned, #{letters_failed_count} failed"
    log "Files: #{files_deleted_count} deleted, #{files_failed_count} failed"
    log "Mode: #{mode}"
  end

  private

  def log(message)
    puts message
    Rails.logger.info message
  end
end

class CacheEventLeadImageJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    Rails.logger.info "========== Starting CacheEventLeadImageJob for event #{event_id} =========="
    event = Event.find(event_id)

    # Skip if no lead_image
    if event.lead_image.blank?
      Rails.logger.info "Skipping event #{event_id}: no lead_image"
      return
    end

    Rails.logger.info "Event #{event_id} lead_image: #{event.lead_image}"
    Rails.logger.info "Event #{event_id} lead_image_cached: #{event.lead_image_cached}"

    begin
      # Check if we need to cache the image
      # We need to cache if:
      # 1. lead_image_cached is blank, OR
      # 2. The cached URL doesn't contain the MD5 hash of the current lead_image, OR
      # 3. The cached file doesn't exist or is not 600x400
      correct_hash = Digest::MD5.hexdigest(event.lead_image)
      needs_caching = event.lead_image_cached.blank? || !event.lead_image_cached.include?(correct_hash)

      # Also check if existing cached file is correct size
      if !needs_caching && event.lead_image_cached.present? && event.lead_image_cached.start_with?("/cached_images/")
        local_path = Rails.root.join("public", event.lead_image_cached.delete_prefix("/"))
        if File.exist?(local_path)
          begin
            require "mini_magick"
            image = MiniMagick::Image.open(local_path)
            if image.width != 600 || image.height != 400
              Rails.logger.info "Cached image is #{image.width}x#{image.height}, not 600x400. Re-caching."
              needs_caching = true
            end
          rescue => e
            Rails.logger.warn "Error checking cached image dimensions: #{e.message}. Re-caching."
            needs_caching = true
          end
        else
          Rails.logger.info "Cached image file missing. Re-caching."
          needs_caching = true
        end
      end

      if needs_caching
        Rails.logger.info "Caching main image for event #{event_id}..."
        cached_url = cache_image_locally(event.lead_image, event.id)
        raise "Failed to cache main image for event #{event_id}" if cached_url.blank?
      else
        cached_url = event.lead_image_cached
        Rails.logger.info "Main image already cached for event #{event_id}"
      end

      # Ensure the 600x400 thumbnail is on disk *before* we publish lead_image_cached.
      # Why: display_lead_image_thumbnail derives the thumbnail URL from lead_image_cached
      # by string substitution and assumes the file exists. If we set lead_image_cached
      # while the thumbnail is missing, the view emits a 404 URL until the next job run.
      if check_thumbnail_exists?(cached_url, event.id, 600, 400, correct_hash)
        Rails.logger.info "Thumbnail already exists for event #{event_id}, skipping"
      else
        Rails.logger.info "Creating thumbnails for event #{event_id}..."
        thumbnail_url = cache_thumbnail_locally(cached_url, event.id, 600, 400)
        raise "Failed to create thumbnail for event #{event_id}" if thumbnail_url.blank?
        Rails.logger.info "Successfully created thumbnail: #{thumbnail_url}"
      end

      if event.lead_image_cached != cached_url
        event.update_column(:lead_image_cached, cached_url)
        Rails.logger.info "Cached main image: #{cached_url}"
      end

      Rails.logger.info "========== Successfully completed job for event #{event.id} =========="
    rescue => e
      Rails.logger.error "Failed to cache lead_image for event #{event.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise # Re-raise to trigger retry
    end
  end

  private

  def check_thumbnail_exists?(cached_url, event_id, width, height, expected_hash)
    # Extract the base filename and extension from the cached lead_image URL
    uri = URI.parse(cached_url)
    base_filename = File.basename(uri.path, ".*")
    source_ext = File.extname(uri.path).downcase

    # Skip if we can't determine extension
    return false if source_ext.blank?

    # Generate expected thumbnail key - preserve the same extension as source
    filename = "#{base_filename}_#{width}x#{height}#{source_ext}"
    local_path = Rails.root.join("public", "cached_images", "events", event_id.to_s, "thumbnails", filename)

    # Check if the thumbnail exists and has the correct hash in filename
    return false unless base_filename.include?(expected_hash)

    # Check if file exists
    File.exist?(local_path)
  rescue => e
    Rails.logger.error "Error checking thumbnail existence: #{e.message}"
    false
  end

  def cached_url?(url)
    # Check if URL is already pointing to our cached images directory
    url.include?("/cached_images/events/")
  end

  def cache_image_locally(url, event_id)
    require "open-uri"
    require "mini_magick"

    # Generate a unique key for the image
    uri = URI.parse(url)
    ext = File.extname(uri.path).downcase

    if ext.blank?
      Rails.logger.warn "Cannot determine file extension for URL: #{url}. Skipping caching."
      return nil
    end

    filename = "#{Digest::MD5.hexdigest(url)}#{ext}"
    relative_path = "events/#{event_id}/lead_image"
    full_directory = Rails.root.join("public", "cached_images", relative_path)
    local_path = full_directory.join(filename)

    Rails.logger.info "Original URL extension: #{File.extname(uri.path)}, using: #{ext}"

    # Create directory if it doesn't exist
    FileUtils.mkdir_p(full_directory)

    # Download the image (bounded so a hung connection can't wedge the worker thread)
    image_data = URI.open(url, open_timeout: 5, read_timeout: 5).read

    # Create temp file for processing
    temp_file = Tempfile.new([ "cache", ext ])
    temp_file.binmode
    temp_file.write(image_data)
    temp_file.close

    # Resize and crop image to exactly 600x400
    image = MiniMagick::Image.open(temp_file.path)
    original_width = image.width
    original_height = image.height

    Rails.logger.info "Original dimensions: #{original_width}x#{original_height}"

    # For GIFs, use coalesce to handle animation frames properly
    if ext == ".gif"
      image.coalesce
      Rails.logger.info "Processing GIF animation"
    end

    # Resize to fill 600x400 and crop to exact size
    image.combine_options do |i|
      i.resize "600x400^"  # Resize to fill
      i.gravity "center"
      i.extent "600x400"   # Crop to exact size
    end

    Rails.logger.info "Resized and cropped to 600x400"

    # Write processed image to local file
    image.write(local_path)
    temp_file.unlink

    Rails.logger.info "Cached to: #{local_path}"

    # Return the public URL path
    "/cached_images/#{relative_path}/#{filename}"
  rescue => e
    Rails.logger.error "Error caching image locally: #{e.message}"
    temp_file&.unlink
    nil
  end

  def content_type_from_url(url)
    ext = File.extname(URI.parse(url).path).downcase
    case ext
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".png" then "image/png"
    when ".gif" then "image/gif"
    when ".webp" then "image/webp"
    else "application/octet-stream"
    end
  end

  def cache_thumbnail_locally(url, event_id, width, height)
    require "open-uri"
    require "mini_magick"

    Rails.logger.info "Starting thumbnail creation for event #{event_id}: #{width}x#{height}"
    Rails.logger.info "Source URL: #{url}"

    # Determine if URL is local cached or external
    if url.start_with?("/cached_images/")
      # Local cached image - read from disk
      local_path = Rails.root.join("public", url.delete_prefix("/"))
      Rails.logger.info "Reading local cached image from: #{local_path}"
      image_data = File.binread(local_path)
    else
      # External URL - download it
      Rails.logger.info "Downloading image..."
      image_data = URI.open(url, open_timeout: 5, read_timeout: 5).read
    end

    Rails.logger.info "Read #{image_data.size} bytes"

    # Detect file extension from URL
    uri = URI.parse(url)
    source_ext = File.extname(uri.path).downcase

    if source_ext.blank?
      Rails.logger.warn "Cannot determine file extension for URL: #{url}. Skipping thumbnail creation."
      return nil
    end

    Rails.logger.info "Source file extension: #{source_ext}"

    # Create a temp file (don't auto-delete it yet)
    temp_file = Tempfile.new([ "thumb", source_ext ])
    temp_file.binmode
    temp_file.write(image_data)
    temp_file.close  # Close the file so MiniMagick can access it
    temp_path = temp_file.path  # Store path before any modifications
    Rails.logger.info "Created temp file: #{temp_path}"

    # Create output temp file - preserve extension for GIFs to maintain animation
    output_file = Tempfile.new([ "thumb_output", source_ext ])
    output_path = output_file.path
    output_file.close  # Close it so ImageMagick can write to it

    # Process with MiniMagick - resize and crop to exact dimensions
    Rails.logger.info "Processing image with MiniMagick..."
    image = MiniMagick::Image.open(temp_path)
    Rails.logger.info "Original dimensions: #{image.width}x#{image.height}, format: #{image.type}"

    # Resize and crop - preserve format for GIFs to maintain animation
    if source_ext == ".gif"
      # For GIFs, use coalesce to handle animation frames properly
      image.coalesce
    end

    image.combine_options do |i|
      i.resize "#{width}x#{height}^"  # Resize to fill
      i.gravity "center"
      i.extent "#{width}x#{height}"   # Crop to exact size
    end

    # Write to output file
    image.write(output_path)
    Rails.logger.info "Processed to #{width}x#{height} and wrote to #{output_path}"

    # Extract the base filename from the cached lead_image URL
    uri = URI.parse(url)
    base_filename = File.basename(uri.path, ".*")  # Get filename without extension (just the hash)

    # Generate filename using the same base filename and extension as the lead_image
    filename = "#{base_filename}_#{width}x#{height}#{source_ext}"
    relative_path = "events/#{event_id}/thumbnails"
    full_directory = Rails.root.join("public", "cached_images", relative_path)
    local_path = full_directory.join(filename)

    Rails.logger.info "Local path: #{local_path}"

    # Create directory if it doesn't exist
    FileUtils.mkdir_p(full_directory)

    # Read the processed image data and write to local file
    processed_image_data = File.binread(output_file.path)
    File.binwrite(local_path, processed_image_data)

    Rails.logger.info "Successfully saved thumbnail locally"

    # Clean up
    temp_file.unlink
    output_file.unlink

    # Return the public URL path
    local_url = "/cached_images/#{relative_path}/#{filename}"
    Rails.logger.info "Thumbnail URL: #{local_url}"
    local_url
  rescue => e
    Rails.logger.error "Error creating thumbnail for event #{event_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    temp_file&.unlink
    output_file&.unlink
    nil
  end
end

class CacheLetterImagesJob < ApplicationJob
  queue_as :default

  def perform(letter_id)
    letter = Letter.find(letter_id)

    total_cached = 0

    # Cache body images only if body_cached is blank
    if letter.body.present? && letter.body_cached.blank?
      # Parse HTML and find all image URLs
      doc = Nokogiri::HTML(letter.body)
      images = doc.css("img")

      images_replaced = false

      images.each do |img|
        src = img["src"]
        next if src.blank?
        next if src.start_with?("data:") # Skip data URLs
        next if cached_url?(src) # Skip if already cached

        begin
          # Download and cache the image
          cached_url = cache_image_locally(src, letter.id)

          # Update the src attribute in the HTML
          if cached_url.present?
            img["src"] = cached_url
            images_replaced = true
            total_cached += 1
          end
        rescue => e
          Rails.logger.error "Failed to cache image #{src} for letter #{letter.id}: #{e.message}"
          # Continue processing other images even if one fails
        end
      end

      # Save the cached version to body_cached if images were replaced
      if images_replaced
        letter.body_cached = doc.to_html
        letter.save
      end
    end

    # Cache lead_image for each event (delegates to CacheEventLeadImageJob which also creates thumbnails)
    letter.events.each do |event|
      next if event.lead_image.blank?

      begin
        CacheEventLeadImageJob.perform_now(event.id)
        total_cached += 1
      rescue => e
        Rails.logger.error "Failed to cache lead_image for event #{event.id}: #{e.message}"
      end
    end

    Log.create!(
      title: "Cached #{total_cached} images locally",
      letter_id: letter.id,
      severity: "normal",
      role: "admin"
    )
  end

  private

  def cached_url?(url)
    # Check if URL is already pointing to our cached images directory
    url.include?("/cached_images/")
  end

  def cache_image_locally(url, letter_id, event_id = nil)
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

    # Use different path for event lead images
    if event_id.present?
      relative_path = "events/#{event_id}/lead_image"
    else
      relative_path = "letters/#{letter_id}/images"
    end

    full_directory = Rails.root.join("public", "cached_images", relative_path)
    local_path = full_directory.join(filename)

    # Create directory if it doesn't exist
    FileUtils.mkdir_p(full_directory)

    # Download the image
    image_data = URI.open(url, open_timeout: 5, read_timeout: 5).read

    # Create temp file for processing
    temp_file = Tempfile.new([ "cache", ext ])
    temp_file.binmode
    temp_file.write(image_data)
    temp_file.close

    # Process image based on whether it's an event lead image or letter body image
    image = MiniMagick::Image.open(temp_file.path)

    if event_id.present?
      # Event lead images: resize and crop to exactly 600x400
      # For GIFs, use coalesce to handle animation frames properly
      if ext == ".gif"
        image.coalesce
      end

      image.combine_options do |i|
        i.resize "600x400^"  # Resize to fill
        i.gravity "center"
        i.extent "600x400"   # Crop to exact size
      end
    else
      # Letter body images: resize to max 1200px width (maintain aspect ratio)
      original_width = image.width
      if original_width > 1200
        image.resize "1200x>"
      end
    end

    # Write processed image to local file
    image.write(local_path)
    temp_file.unlink

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
end

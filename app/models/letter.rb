class Letter < ApplicationRecord
  belongs_to :venue
  has_many :events, dependent: :destroy
  has_many :llm_jobs
  has_many :logs, dependent: :nullify

  validates :status, inclusion: { in: %w[precheck ignored pending processed error] }, allow_nil: true

  def strip_email
    doc = Nokogiri::HTML(body.to_s.force_encoding("UTF-8"), nil, Encoding::UTF_8.to_s)

    doc.xpath("//script")&.remove
    doc.xpath("//style")&.remove
    doc.xpath("//comment()").remove

    doc.xpath(".//*").each do |node|
      if node.name == "img"
        t = node.dup
        src = node.attr("src")
        t.inner_html = src ? " [img]#{src}[/img] " : ""
        node.replace t.text
      end
    end

    %w[p div h1 h2 h3 h4 h5 h6 li tr].each do |tag|
      doc.xpath("//#{tag}").each { |node| node.prepend_child(Nokogiri::XML::Text.new("\n", doc)) }
    end
    doc.xpath("//br").each { |node| node.replace(Nokogiri::XML::Text.new("\n", doc)) }
    %w[span a td th strong em b i].each do |tag|
      doc.xpath("//#{tag}").each { |node| node.add_next_sibling(Nokogiri::XML::Text.new(" ", doc)) }
    end

    text_version = doc.text
    text_version = text_version.gsub(/\t/, " ")
    text_version = text_version.gsub("\r\n", "\n")
    text_version = text_version.gsub(/[ \t]+/, " ")
    text_version = text_version.gsub(/^ +$/m, "")
    text_version = text_version.gsub(/\n{3,}/, "\n\n")
    text_version = text_version.strip

    update!(text_version: text_version)
  end

  def create_llm_job
    default_prompt = Prompt.find_by(title: "default")
    return unless default_prompt

    default_model = Setting.find_by(name: "model")&.value
    blacklisted_urls = Blacklist.pluck(:url).to_set

    strip_email

    substitutions = []
    counter = 0

    substituted_text = text_version.to_s.gsub(/\[img\](.*?)\[\/img\]/m) do
      url = Regexp.last_match(1).strip
      next "" if blacklisted_urls.include?(url)

      counter += 1
      short = "{{sub-#{counter}}}"
      substitutions << { long: url, short: short }
      short
    end

    ActiveRecord::Base.transaction do
      llm_job = LlmJob.create!(
        prompt: default_prompt.text
          .gsub("{{{text}}}", substituted_text)
          .gsub('#{today}', Date.today.strftime("%Y-%m-%d"))
          .gsub('#{sent_date}', sent_date.strftime("%Y-%m-%d")),
        status: "new",
        letter: self,
        model: default_model
      )

      substitutions.each do |s|
        llm_job.substitutes.create!(long: s[:long], short: s[:short])
      end

      update!(status: "pending")
    end
  end

  def display_body
    body_cached.presence || body
  end

  def strip_pii(html)
    return html if html.blank?

    # # Remove tracking pixels (img tags with 1x1 dimensions or tracking domains)
    # # html = html.gsub(/<img[^>]*(?:width="1"|height="1"|tracking|pixel|beacon)[^>]*>/i, '')

    # # Remove tracking URLs and parameters
    # html = html.gsub(/\?(?:[^"'\s]*(?:utm_|fbclid|gclid|msclkid|mc_|_hsenc|_hsmi)[^"'\s]*)/i, "")

    # # Remove UUID-like patterns (8-4-4-4-12 hex format)
    # html = html.gsub(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i, "")

    # # Remove common tracking tokens/parameters
    # html = html.gsub(/[?&](?:token|sid|ssid|sessionid|trackid|clickid|userid)=[^&"'\s]*/i, "")

    # # Remove email tracking beacons and open trackers
    # html = html.gsub(/<img[^>]*src="[^"]*(?:track|open|beacon|pixel)[^"]*"[^>]*>/i, "")

    # # Remove script tags that might contain tracking
    # html = html.gsub(/<script[^>]*>.*?<\/script>/im, "")

    # # Remove noscript tags that might contain tracking pixels
    # html = html.gsub(/<noscript[^>]*>.*?<\/noscript>/im, "")

    # # Remove long base64-like tracking strings (15+ chars of alphanumeric with - and _) but preserve img tags
    # # Split HTML into parts, preserving img tags
    parts = html.split(/(<img[^>]*>)/i)

    # Process only non-img parts
    parts.map! do |part|
      if part.match?(/^<img[^>]*>$/i)
        part # Keep img tags unchanged
      else
        part.gsub(/[A-Za-z0-9_-]{15,}/, "") # Remove tracking strings from text
      end
    end

    html = parts.join

    # Remove href attributes from all links while keeping formatting
    html = html.gsub(/(<a[^>]*)\s+href="[^"]*"([^>]*>)/i, '\1\2')

    # Remove venue code from content
    html = html.gsub(venue.code, "") if venue&.code.present?

    html
  end
end

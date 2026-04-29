module DateHelper
  def format_date(start_date_utc, end_date_utc)
    current_year = Time.current.strftime("%Y").to_i

    start_date = start_date_utc&.in_time_zone
    end_date = end_date_utc&.in_time_zone

    if start_date != nil && end_date != nil

      start_time = start_date.strftime("%H:%M")
      end_time = end_date.strftime("%H:%M")

      start_time_year = start_date.strftime("%Y").to_i
      end_time_year = end_date.strftime("%Y").to_i

      if start_date.to_date === end_date.to_date
        day_name = start_date.strftime("%a")
        if start_time == "00:00" && end_time == "23:59"
          # all day event
          year = ""
          if start_time_year != current_year
            year = " " + start_time_year.to_s
          end
          ret = "#{day_name} #{start_date.strftime('%e %B')}#{year}"
        elsif start_time != end_time
          # same day different times
          year = ""
          if start_time_year != current_year
            year = " " + start_time_year.to_s
          end

          visible_start = start_time == "00:00" ? nil : start_time
          visible_end = end_time == "00:00" ? nil : end_time
          time_range = [ visible_start, visible_end ].compact.join("–")
          time_part = time_range.present? ? ", #{time_range}" : ""
          ret = "#{day_name} #{start_date.strftime('%e %B')}#{time_part}#{year}"

        else
          # same day, same times
          time_part = start_time == "00:00" ? "" : ", #{start_time}"
          ret = "#{day_name} #{start_date.strftime('%e %B')}#{time_part}"
        end
        ret
      else
        # different days
        start_day_name = start_date.strftime("%a")
        end_day_name = end_date.strftime("%a")
        start_time_year = start_date.strftime("%Y").to_i
        year = ""
        if start_time_year != current_year
          year = " " + start_time_year.to_s
        end
        ret = "#{start_day_name} #{start_date.strftime('%e %B')} – #{end_day_name} #{end_date.strftime('%e %B %Y')}"
        # ret += ', different days'
      end
    else
      # only end date
      ret = nil
      if end_date
        ret = "Until " + end_date.strftime("%e %B %Y")
      end
      # only start date
      if start_date
        ret = start_date.strftime("%e %B")
        time_str = start_date.strftime("%H:%M")
        ret += ", " + (time_str == "00:00" ? start_date.strftime("%Y") : start_date.strftime("%H:%M %Y"))
        # ret += ', start date only'
      end
      ret
    end
  end
end

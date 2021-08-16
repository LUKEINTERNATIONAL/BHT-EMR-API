# frozen_string_literal: true

module TimeUtils
  class << self
    def time_epoch
      Time.now - 120.years
    end

    def date_epoch
      Date.today - 120.years
    end

    def date_range(datetime)
      start_of_day(datetime)..end_of_day(datetime)
    end

    # Returns a 24 hour period (day) containing the date
    def day_bounds(datetime)
      [start_of_day(datetime), end_of_day(datetime)]
    end

    def start_of_day(date)
      return nil unless date

      date.to_date.to_time
    end

    def end_of_day(date)
      return nil unless date

      date.to_date.strftime('%Y-%m-%d 23:59:59').to_time
    end

    # Returns a time object comprising the given date plus the current time.
    def retro_timestamp(date)
      return nil unless date

      date = date.to_time
      "#{date.strftime('%Y-%m-%d')} #{Time.now.strftime('%H:%M:%S')}".to_time
    end

    def get_person_age (birthdate:)
      ((Time.zone.now - birthdate.to_time) / 1.year.seconds).floor
    end
  end
end

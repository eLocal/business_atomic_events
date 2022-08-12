# frozen_string_literal: true

require 'sidekiq'

module BusinessAtomicEvents
  # Generate historic feeds
  class SpawnHistoricFeeds
    include Sidekiq::Worker

    DAYS_IN_SINGLE_RUN = 15
    HOURS_PER_DAY = 24
    REF_TZ = 'America/New_York'
    TIME_INTERVAL = 10.minutes.freeze

    def perform(start_date_str, end_date_str) # rubocop:disable Metrics/AbcSize
      Rails.logger.info "BAE_History -- starting with arguments #{start_date_str} and #{end_date_str}"
      return unless Flipper.enabled?(:bae_history_feeds)

      Rails.logger.info 'BAE_History -- feature enabled!'
      start_date = start_date_str.to_date
      end_date = end_date_str.to_date
      batch_start_date = end_date - DAYS_IN_SINGLE_RUN + 1
      is_last_batch = start_date >= batch_start_date
      batch_start_date = start_date if is_last_batch
      Rails.logger.info "BAE_History -- processing period #{batch_start_date} - #{end_date}"
      a_time = end_date.in_time_zone(REF_TZ) + HOURS_PER_DAY.hours
      ((end_date - batch_start_date + 1) * HOURS_PER_DAY).to_i.times do
        # puts "generating for end time #{a_time}"
        FeedGenerator.perform_async(a_time.to_s)
        a_time -= 1.hour
      end

      Rails.logger.info "BAE_History -- done with feeds for period #{batch_start_date} - #{end_date}"

      unless is_last_batch # rubocop:disable Style/GuardClause
        self.class.perform_in(TIME_INTERVAL, start_date.to_s, (batch_start_date - 1).to_s)

        Rails.logger.info(
          "BAE_History -- queued feeds job for period #{start_date} - #{(batch_start_date - 1)}"
        )
      end
    end
  end
end

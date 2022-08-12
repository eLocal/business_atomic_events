# frozen_string_literal: true

require 'sidekiq'

module BusinessAtomicEvents
  # Generate feeds specified in the configuration file
  class FeedGenerator
    include Sidekiq::Worker

    CONFIG_NAME = :business_atomic_events
    PERIOD_DURATION = 1.hour.freeze

    # We want this job to be spawned without parameters as a cron-based periodic job for current feeds,
    # as well as in the batch mode where the period to report on is passed by the caller
    def perform(period_stop_time_str = nil)
      return if period_stop_time_str.nil? && !Flipper.enabled?(:bae_current_feeds)

      stop_time = period_stop_time_str.blank? ? latest_period_stop_time : Time.zone.parse(period_stop_time_str)
      start_time = stop_time - PERIOD_DURATION
      iterate_over_config(period_stop_time_str, start_time, stop_time)
    end

    private

    def iterate_over_config(period_stop_time_str, start_time, stop_time)
      config = Rails.application.config_for(CONFIG_NAME)
      with_readonly_db do
        config.items.each do |c|
          full_index = full_index_name(config[:index_prefix], c[:index])
          Runner.perform_async(full_index, c[:query], start_time.to_s, stop_time.to_s) \
            if period_stop_time_str.nil? || Flipper.enabled?("bae_history_#{c[:index]}".to_sym)
        end
      end
    end

    def latest_period_stop_time
      Time.current.beginning_of_hour
    end

    def full_index_name(prefix, index_name)
      "#{prefix}_#{index_name}"
    end
  end
end

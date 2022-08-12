# frozen_string_literal: true

require 'business_atomic_events/database_selection_helper'
require 'sidekiq'
require 'stringio'

module BusinessAtomicEvents
  # Generate and send feeds for the specified OpenSearch index
  class Runner
    include Sidekiq::Worker
    include DatabaseSelectionHelper

    attr_reader :body_stream

    OPEN_SOURCE_URL = 'https://search-john-test-duj2npqk5k27ffd2uwgb52rm7i.us-east-1.es.amazonaws.com'
    OPERATION = '_bulk'

    def perform(target, query, start_time_str, stop_time_str)
      query_results = execute_query(query, start_time_str, stop_time_str)
      return if query_results.empty?

      @body_stream = StringIO.new
      query_results.rows.each { |record| store_record(record, query_results.columns, stop_time_str) }
      url = "#{OPEN_SOURCE_URL}/#{target}/#{OPERATION}"
      response = HTTParty.post(url, basic_auth: basic_auth, body: body_stream.string, headers: post_headers)
      Rails.logger.info("Business Events - target: #{target}, period: #{start_time_str} - #{stop_time_str}," \
                        " status: #{response.code}, body: #{response.body}")
    end

    private

    def execute_query(query, start_time_str, stop_time_str)
      qry_proc = lambda {
        ActiveRecord::Base.connection.exec_query(
          query,
          nil,
          [[nil, utc_time_str(start_time_str)], [nil, utc_time_str(stop_time_str)]]
        )
      }
      begin
        with_readonly_db(&qry_proc)
      rescue ActiveRecord::SerializationFailure
        with_writable_db(&qry_proc)
      end
    end

    def store_record(record, columns, period_stop_time)
      res = { stop_time: period_stop_time.to_time.iso8601(3) }
      columns.each_with_index { |col_name, idx| res[col_name] = record[idx] }
      body_stream.puts({ create: {} }.to_json)
      body_stream.puts(res.to_json)
    end

    def basic_auth
      { username: ENV['OPEN_SEARCH_USER'], password: ENV['OPEN_SEARCH_PASSWORD'] }
    end

    def post_headers
      { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
    end

    def utc_time_str(time_with_zone_str)
      Time.zone.parse(time_with_zone_str).utc.to_s
    end
  end
end

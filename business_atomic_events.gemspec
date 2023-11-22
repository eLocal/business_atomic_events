# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'business_atomic_events'
  s.version     = '0.0.9'
  s.date        = '2023-11-22'
  s.summary     = 'Generate and send data about certain system events to OpenSearch'
  s.description = 'Generate and send data about certain system events to OpenSearch'
  s.authors     = ['Greg Garber']
  s.email       = 'greg_garber@elocal.com'
  s.files       = ['lib/business_atomic_events.rb']
  s.homepage    = 'https://github.com/elocal/business_atomic_events'
  s.license     = 'private'
  s.add_runtime_dependency 'rails'
  s.add_runtime_dependency 'sidekiq'
  s.add_runtime_dependency 'syslogger'
end

# frozen_string_literal: true

# Allow to switch between readonly and read-write databases
module DatabaseSelectionHelper
  ROLE_READING = :reading
  ROLE_WRITING = :writing

  def with_writable_db(&blk)
    if main_replica_exists?
      ActiveRecord::Base.connected_to(role: ROLE_WRITING) { blk.call }
    else
      blk.call
    end
  end

  def with_readonly_db(&blk)
    if main_replica_exists?
      ActiveRecord::Base.connected_to(role: ROLE_READING) { blk.call }
    else
      blk.call # in environments with only one (writable) database, we cannot do any better than that
    end
  end

  def main_replica_exists?
    return @main_replica_exists unless @main_replica_exists.nil?

    conf = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'replica', include_replicas: true)
    @main_replica_exists = conf.present? && conf.replica?
  end
end

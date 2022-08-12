# frozen_string_literal: true

# Allow to switch between readonly and read-write databases
module DatabaseSelectionHelper
  ROLE_READING = :reading
  ROLE_WRITING = :writing

  def with_writable_db(&blk)
    if readonly_replica_exists?
      ActiveRecord::Base.connected_to(role: ROLE_WRITING) { blk.call }
    else
      blk.call
    end
  end

  def with_readonly_db(&blk)
    if readonly_replica_exists?
      ActiveRecord::Base.connected_to(role: ROLE_READING) { blk.call }
    else
      blk.call # in environments with only one (writable) database, we cannot do any better than that
    end
  end

  def readonly_replica_exists?
    Rails.env.production? || Rails.env.stage?
  end
end

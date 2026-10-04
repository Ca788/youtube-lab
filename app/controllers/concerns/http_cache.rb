# frozen_string_literal: true

module HttpCache
  extend ActiveSupport::Concern

  COLLECTION_TTL = 15.seconds
  RESOURCE_TTL = 30.seconds

  included do
    etag { serializer_view_param }
  end

  # @param [ActiveRecord::Relation] relation
  # @param [ActiveSupport::Duration] ttl
  # @return [Boolean]
  def stale_collection?(relation, ttl: COLLECTION_TTL)
    conditional_get(relation.total_count, relation.maximum(:updated_at), ttl)
  end

  # @param [ActiveRecord::Relation] relation
  # @param [Time, nil] last_modified
  # @param [ActiveSupport::Duration] ttl
  # @return [Boolean]
  def stale_aggregate?(relation, last_modified:, ttl: COLLECTION_TTL)
    conditional_get(relation.total_count, last_modified, ttl)
  end

  # @param [ActiveRecord::Base] record
  # @param [ActiveSupport::Duration] ttl
  # @return [Boolean]
  def stale_resource?(record, ttl: RESOURCE_TTL)
    expires_in ttl, public: false

    stale?(record)
  end

  private

  # @param [Integer] count
  # @param [Time, nil] last_modified
  # @param [ActiveSupport::Duration] ttl
  # @return [Boolean]
  def conditional_get(count, last_modified, ttl)
    expires_in ttl, public: false

    stale?(etag: [count, last_modified], last_modified: last_modified)
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: youtube_viewer_samples
#
#  id                 :uuid             not null, primary key
#  captured_at        :datetime         not null
#  concurrent_viewers :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  live_stream_id     :uuid             not null
#
# Indexes
#
#  index_youtube_viewer_samples_on_live_stream_id                  (live_stream_id)
#  index_youtube_viewer_samples_on_live_stream_id_and_captured_at  (live_stream_id,captured_at)
#
# Foreign Keys
#
#  fk_rails_...  (live_stream_id => youtube_live_streams.id)
#
module Youtube
  class ViewerSample < ApplicationRecord
    belongs_to :live_stream, class_name: "Youtube::LiveStream"

    validates :concurrent_viewers, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :captured_at, presence: true

    scope :captured_between, lambda { |from, to|
      relation = all
      relation = relation.where(captured_at: from..) if from.present?
      relation = relation.where(captured_at: ..to) if to.present?
      relation
    }
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: youtube_live_streams
#
#  id                   :uuid             not null, primary key
#  actual_end_at        :datetime
#  actual_start_at      :datetime
#  channel_title        :string
#  chat_next_page_token :string
#  concurrent_viewers   :integer
#  last_polled_at       :datetime
#  like_count           :bigint
#  scheduled_start_at   :datetime
#  status               :string           default("none"), not null
#  title                :string
#  total_view_count     :bigint
#  tracking             :boolean          default(FALSE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  channel_id           :string
#  live_chat_id         :string
#  user_id              :uuid             not null
#  video_id             :string           not null
#
# Indexes
#
#  index_youtube_live_streams_on_tracking              (tracking)
#  index_youtube_live_streams_on_user_id               (user_id)
#  index_youtube_live_streams_on_user_id_and_status    (user_id,status)
#  index_youtube_live_streams_on_user_id_and_video_id  (user_id,video_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
module Youtube
  class LiveStream < ApplicationRecord
    STATUSES = {
      none:      "none",
      upcoming:  "upcoming",
      live:      "live",
      completed: "completed"
    }.freeze

    belongs_to :user

    has_many :viewer_samples,
             class_name: "Youtube::ViewerSample",
             dependent:  :destroy

    has_many :chat_messages,
             class_name: "Youtube::ChatMessage",
             dependent:  :destroy

    enum :status, STATUSES, prefix: :status

    validates :video_id, presence: true, uniqueness: { scope: :user_id }
    validates :status, presence: true

    scope :by_status, ->(status) { where(status: status) if status.present? && STATUSES.value?(status.to_s) }
    scope :tracking,  -> { where(tracking: true) }

    # @return [Boolean]
    def chat_pollable?
      live_chat_id.present? && !status_completed?
    end
  end
end

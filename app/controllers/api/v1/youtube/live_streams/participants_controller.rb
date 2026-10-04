# frozen_string_literal: true

class Api::V1::Youtube::LiveStreams::ParticipantsController < Api::BaseController
  def index
    participants = UseCase::Youtube::ListChatParticipantsUseCase.new.call(
      user:           @user,
      live_stream_id: params[:live_stream_id],
      order:          params[:order]
    ).page(page_param).per(per_page_param)

    return unless stale_aggregate?(participants, last_modified: last_message_at(participants))

    render json: ApiResponseSerializer.render_data_array(
      participants,
      serializer:      V1::Youtube::ChatParticipantSerializer,
      serializer_view: serializer_view_param,
      pagination:      pagination_for(participants)
    ), status: :ok
  end

  private

  # @param [ActiveRecord::Relation] participants
  # @return [Time, nil]
  def last_message_at(participants)
    participants.filter_map(&:last_message_at).max
  end
end

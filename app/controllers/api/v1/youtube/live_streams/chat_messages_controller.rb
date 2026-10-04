# frozen_string_literal: true

class Api::V1::Youtube::LiveStreams::ChatMessagesController < Api::BaseController
  def index
    messages = UseCase::Youtube::ListChatMessagesUseCase.new.call(
      user:           @user,
      live_stream_id: params[:live_stream_id],
      **filters
    ).page(page_param).per(per_page_param)

    render json: ApiResponseSerializer.render_data_array(
      messages,
      serializer:      V1::Youtube::ChatMessageSerializer,
      serializer_view: serializer_view_param,
      pagination:      pagination_for(messages)
    ), status: :ok
  end

  private

  def filters
    {
      message_type:      params[:message_type],
      author_channel_id: params[:author_channel_id],
      paid_only:         ActiveModel::Type::Boolean.new.cast(params[:paid_only]).present?
    }
  end
end

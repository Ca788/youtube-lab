# frozen_string_literal: true

class Api::V1::Youtube::LiveStreamsController < Api::BaseController
  def index
    live_streams = UseCase::Youtube::ListLiveStreamsUseCase.new.call(
      user:     @user,
      status:   params[:status],
      tracking: tracking_filter
    ).page(page_param).per(per_page_param)

    return unless stale_collection?(live_streams)

    render json: ApiResponseSerializer.render_data_array(
      live_streams,
      serializer:      V1::Youtube::LiveStreamSerializer,
      serializer_view: serializer_view_param,
      pagination:      pagination_for(live_streams)
    ), status: :ok
  end

  def show
    live_stream = @user.live_streams.find(params[:id])

    return unless stale_resource?(live_stream)

    render json: ApiResponseSerializer.render(
      live_stream,
      serializer:      V1::Youtube::LiveStreamSerializer,
      serializer_view: :extended
    ), status: :ok
  end

  def create
    live_stream = UseCase::Youtube::TrackLiveStreamUseCase.new.call(
      user: @user,
      url:  live_stream_params[:url]
    )

    render json: ApiResponseSerializer.render(
      live_stream,
      serializer:      V1::Youtube::LiveStreamSerializer,
      serializer_view: :extended,
      message:         "Live stream tracked successfully."
    ), status: :created
  end

  def sync
    live_stream = @user.live_streams.find(params[:id])
    live_stream = UseCase::Youtube::SyncLiveStreamUseCase.new.call(live_stream: live_stream)
    UseCase::Youtube::PollChatMessagesUseCase.new.call(live_stream: live_stream)

    render json: ApiResponseSerializer.render(
      live_stream,
      serializer:      V1::Youtube::LiveStreamSerializer,
      serializer_view: :extended,
      message:         "Live stream synced successfully."
    ), status: :ok
  end

  def destroy
    UseCase::Youtube::StopTrackingLiveStreamUseCase.new.call(
      user: @user,
      id:   params[:id]
    )

    render json: ApiResponseSerializer.render(
      {},
      message: "Live stream tracking stopped successfully."
    ), status: :ok
  end

  private

  def live_stream_params
    params.require(:live_stream).permit(:url)
  end

  def tracking_filter
    return nil if params[:tracking].blank?

    ActiveModel::Type::Boolean.new.cast(params[:tracking])
  end
end

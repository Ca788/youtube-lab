# frozen_string_literal: true

class Api::V1::Youtube::LiveStreams::ViewerSamplesController < Api::BaseController
  def index
    samples = UseCase::Youtube::ListViewerSamplesUseCase.new.call(
      user:           @user,
      live_stream_id: params[:live_stream_id],
      from:           params[:from],
      to:             params[:to]
    ).page(page_param).per(per_page_param)

    return unless stale_collection?(samples)

    render json: ApiResponseSerializer.render_data_array(
      samples,
      serializer:      V1::Youtube::ViewerSampleSerializer,
      serializer_view: serializer_view_param,
      pagination:      pagination_for(samples)
    ), status: :ok
  end
end

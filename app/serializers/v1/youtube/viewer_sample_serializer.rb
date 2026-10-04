# frozen_string_literal: true

class V1::Youtube::ViewerSampleSerializer < Blueprinter::Base
  identifier :id

  view :default do
    fields :concurrent_viewers, :captured_at
  end

  view :extended do
    include_view :default

    fields :created_at
  end
end

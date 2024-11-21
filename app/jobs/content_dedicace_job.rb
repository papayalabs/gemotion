class ContentDedicaceJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: false

  def perform(video_id)
    video = Video.find(video_id)
    video.update!(concat_status: :processing)

    service = ContentDedicaceService.new(video)
    result = service.call

    if result[:error]
      video.update!(concat_status: :failed)
    else
      video.update!(concat_status: :completed)
    end
  end
end
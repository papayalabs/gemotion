module DedicaceSharedBehavior
  extend ActiveSupport::Concern

  included do
    belongs_to :dedicace
    belongs_to :video
    has_one_attached :creator_end_dedication_video
  end

  def video_duration
    return unless creator_end_dedication_video.attached?

    video_path = ActiveStorage::Blob.service.path_for(creator_end_dedication_video.key)
    duration = `ffprobe -v quiet -show_format -print_format json "#{video_path}" | jq -r .format.duration`
    Time.at(duration.to_f).utc.strftime("%H:%M:%S")
  end
end
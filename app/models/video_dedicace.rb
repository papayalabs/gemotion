class VideoDedicace < ApplicationRecord
  include DedicaceSharedBehavior

  belongs_to :video
  belongs_to :dedicace

  has_many :video_dedicace_slots, dependent: :destroy

  has_one_attached :creator_end_dedication_video
  has_one_attached :creator_end_dedication_video_uploaded

  def video_duration
    if video.attached? && video.blob.present?
      analyzer = ActiveStorage::Analyzer::VideoAnalyzer.new(video.blob)
      metadata = analyzer.metadata
      metadata[:duration] if metadata
    else
      "N/A"
    end
  end

  def update_video_slot(slot_number, video_file, preview_data)
    update(
      "video_slot_#{slot_number}" => video_file.original_filename,
      "video_slot_#{slot_number}_preview" => preview_data
    )
  end
end

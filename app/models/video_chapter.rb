class VideoChapter < ApplicationRecord
  belongs_to :chapter_type
  belongs_to :video
  has_one_attached :element
  has_many_attached :videos
  has_many_attached :photos
  has_one :video_music, dependent: :destroy

  validates :text, presence: true

  before_destroy :remove_video_music

  # Fetch videos in the saved order
  def ordered_videos
    # Ensure ordered_videos_ids is an array of IDs as strings
    video_ids = ordered_videos_ids.map(&:to_s)
    videos.sort_by { |v| video_ids.index(v.id.to_s) || videos.size }
  end

  # Fetch photos in the saved order
  def ordered_photos
    # Ensure ordered_images_ids is an array of IDs as strings
    image_ids = ordered_images_ids.map(&:to_s)
    photos.sort_by { |p| image_ids.index(p.id.to_s) || photos.size }.reverse
  end

  private

  def remove_video_music
    video_music&.destroy
  end
end

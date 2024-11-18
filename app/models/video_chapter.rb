class VideoChapter < ApplicationRecord
  belongs_to :chapter_type
  belongs_to :video
  # has_one_attached :element
  has_many_attached :videos
  has_many_attached :photos
  has_one :video_music, dependent: :destroy
  # validates :order, numericality: { only_integer: true }

  validates :text, presence: true

  before_destroy :remove_video_music

  # Fetch videos in the saved order
  def ordered_videos
    # Ensure ordered_videos_ids is an array of IDs as strings
    video_filenames = (videos_order || '').split(',').map(&:strip)
    videos.sort_by { |v| video_filenames.index(v.filename.to_s) || videos.size }
  end

  # Fetch photos in the saved order
  def ordered_photos
    # Ensure ordered_images_ids is an array of IDs as strings
    photo_filenames = (photos_order || '').split(',').map(&:strip)
    photos.sort_by { |p| photo_filenames.index(p.filename.to_s) || photos.size }
  end

  def videos_order_list
    videos_order.split(',')
  end

  def photos_order_list
    photos_order.split(',')
  end

  private

  def remove_video_music
    video_music&.destroy
  end
end

class VideoChapter < ApplicationRecord
  belongs_to :chapter_type
  belongs_to :video
  has_one_attached :element
  has_many_attached :videos
  has_many_attached :photos
  has_one :video_music, dependent: :destroy

  validates :text, presence: true

  before_destroy :remove_video_music
  private

  def remove_video_music
    video_music&.destroy
  end
end

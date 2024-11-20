class VideoChapter < ApplicationRecord
  include ChapterSharedBehavior

  has_one :video_music, dependent: :destroy
  before_destroy :remove_video_music

  private

  def remove_video_music
    video_music&.destroy
  end
end
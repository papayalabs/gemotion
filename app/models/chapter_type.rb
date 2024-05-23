class ChapterType < ApplicationRecord
  has_one_attached :image

  has_many :video_chapters
end

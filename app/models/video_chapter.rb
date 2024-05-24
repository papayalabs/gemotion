class VideoChapter < ApplicationRecord
  belongs_to :chapter_type
  belongs_to :video
  has_one_attached :element

  validates :text, presence: true
end

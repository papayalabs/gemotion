class VideoChapter < ApplicationRecord
  belongs_to :chapter_type
  belongs_to :video
  has_many_attached :elements

  validates :text, presence: true
end

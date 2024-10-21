class VideoMusic < ApplicationRecord
  belongs_to :music
  belongs_to :video_chapter, optional: true

end

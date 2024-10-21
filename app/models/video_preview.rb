class VideoPreview < ApplicationRecord
  belongs_to :preview
  belongs_to :video
end
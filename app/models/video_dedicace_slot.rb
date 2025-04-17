class VideoDedicaceSlot < ApplicationRecord
  belongs_to :video_dedicace

  has_one_attached :video
  has_one_attached :preview
end

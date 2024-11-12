class Dedicace < ApplicationRecord
  has_one_attached :video
  has_one_attached :creator_end_dedication_video
end

class Preview < ApplicationRecord
  has_one_attached :image
  has_many :video_previews, dependent: :destroy
end

class Music < ApplicationRecord
  has_one_attached :music
  has_many :video_musics, dependent: :destroy
end

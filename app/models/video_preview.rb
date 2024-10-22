class VideoPreview < ApplicationRecord
  belongs_to :preview
  belongs_to :video
  validates :order, presence: true, numericality: { only_integer: true }
end
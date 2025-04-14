class Preview < ApplicationRecord
  TRANSITION_TYPES = %w[dissolve flash directional zoom swap_instant radial centered_drop cube heart].freeze
  
  has_one_attached :image
  has_many :video_previews, dependent: :destroy
  
  validates :transition_type, inclusion: { in: TRANSITION_TYPES }, allow_nil: true
end

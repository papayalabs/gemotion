class DedicaceContent < ApplicationRecord
  belongs_to :video
  has_one_attached :content
end

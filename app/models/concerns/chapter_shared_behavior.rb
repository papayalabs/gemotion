module ChapterSharedBehavior
  extend ActiveSupport::Concern

  included do
    belongs_to :chapter_type
    belongs_to :video
    # has_one_attached :element
    has_many_attached :videos
    has_many_attached :photos
    # validates :order, numericality: { only_integer: true }

    validates :text, presence: true
  end

  def ordered_videos
    video_filenames = (videos_order || '').split(',').map(&:strip)
    videos.sort_by { |v| video_filenames.index(v.filename.to_s) || videos.size }
  end

  def ordered_photos
    photo_filenames = (photos_order || '').split(',').map(&:strip)
    photos.sort_by { |p| photo_filenames.index(p.filename.to_s) || photos.size }
  end

  # def videos_order_list
  #   videos_order.split(',')
  # end

  # def photos_order_list
  #   photos_order.split(',')
  # end


end
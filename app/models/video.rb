class Video < ApplicationRecord
    enum :video_type, { solo: 0, colab: 1 }
    enum :occasion, { anniversaire: 0, mariage: 1 }
    enum :theme, {specific_request: 0, theme_1: 1, theme_2: 2}
    enum :music_type, { whole_video: 0, by_chapters: 1 }

    has_many :video_destinataires, dependent: :destroy
    has_many :video_chapters, dependent: :destroy
    has_many :dedicace_contents, dependent: :destroy

    # has_many :video_musics, dependent: :destroy
    # has_many :musics, through: :video_musics

    has_many :video_previews, dependent: :destroy
    has_many :previews, through: :video_previews

    has_one_attached :final_video

    belongs_to :music, optional: true
    belongs_to :dedicace, optional: true

    SOLO_WAY = ['start', 'occasion', 'info_destinataire', 'date_fin', 'introduction', 'photo_intro', 'select_chapters', 'music', 'dedicace', 'share', 'content', 'content_dedicace', 'deadline', 'render']
    COLAB_WAY = ['start', 'occasion', 'info_destinataire', 'date_fin', 'introduction', 'photo_intro', 'select_chapters', 'music', 'dedicace', 'share', 'content', 'content_dedicace', 'deadline', 'render']

    def video_destinataire
        self.video_destinataires.last
    end

    def generate_token
        self.token = SecureRandom.urlsafe_base64(20)
        generate_token if Video.exists?(token: self.token)
    end

    def validate_start
        Video.video_types.keys.include?(self.video_type.downcase()) && self.way.include?(self.stop_at)
    end

    def validate_occasion
        Video.occasions.keys.include?(self.occasion.downcase()) && self.way.include?(self.stop_at)
    end

    def validate_destinataire(video_destinataire)
        VideoDestinataire.genres.keys.include?(video_destinataire.genre) && self.way.include?(self.stop_at)
    end

    def validate_info_destinataire(video_destinataire)
        return false if video_destinataire.name.empty?
        return false if video_destinataire.age.nil? || !video_destinataire.age.is_a?(Numeric)
        return false if video_destinataire.more_info.empty?
        return false unless self.way.include?(self.stop_at)
        return true
    end

    def validate_date_fin
        return false if self.end_date.nil? || !self.end_date.is_a?(ActiveSupport::TimeWithZone)
        return false unless self.way.include?(self.stop_at)
        return true
    end

    def validate_introduction
        return false unless Video.themes.include?(self.theme.downcase())
        return false if self.specific_request? && self.theme_specific_request.blank?
        return false unless self.way.include?(self.stop_at)
        return true
    end

    def validate_photo_intro
        return false if previews.count > 3 || previews.count == 0
        return true
    end

    def next_step
        curr_step = self.way.find_index self.stop_at
        return 0 if curr_step.nil?
        return self.way.size if self.finish?
        return self.way[curr_step+1]
    end

    def finish?
        self.current_step() == self.way.last
    end

    def current_step
        curr_step = self.way.find_index self.stop_at
        return self.way[0] if curr_step.nil?
        return self.way[curr_step]
    end

    def previous_step
        curr_step = self.way.find_index self.stop_at
        return self.way[0] if curr_step.nil? || curr_step <= 0
        return self.way[curr_step-1]
    end

    def way
        return SOLO_WAY if self.video_type == 'solo'
        return COLAB_WAY
    end
end

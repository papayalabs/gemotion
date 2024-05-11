class Video < ApplicationRecord
    enum :video_type, { solo: 0, colab: 1 }
    enum :occasion, { anniversaire: 0, mariage: 1 }

    has_many :video_destinataires

    SOLO_WAY = ['start', 'occasion', 'destinataire', 'info_destinataire', 'date_fin', 'intro', 'photo_intro']
    COLAB_WAY = ['start', 'occasion', 'destinataire', 'info_destinataire', 'date_fin', 'intro', 'photo_intro']

    def video_destinataire
        self.video_destinataires.last
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
        return true 
    end

    def validate_date_fin
        return false if self.end_date.nil? || !self.end_date.is_a?(DateTime)
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
        return 0 if curr_step.nil?
        return self.way[curr_step]
    end

    def previous_step
        curr_step = self.way.find_index self.stop_at
        return 0 if curr_step.nil? || curr_step <= 0
        return self.way[curr_step-1]
    end

    def way 
        return SOLO_WAY if self.video_type == 'solo'
        return COLAB_WAY
    end
end

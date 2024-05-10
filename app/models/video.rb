class Video < ApplicationRecord
    enum :video_type, { solo: 0, colab: 1 }
    enum :occasion, { anniversaire: 0, mariage: 1 }


    SOLO_WAY = ['start', 'occasion', 'destinataire', 'info_destinataire', 'date_fin', 'intro', 'photo_intro']
    COLAB_WAY = ['start', 'occasion', 'destinataire', 'info_destinataire', 'date_fin', 'intro', 'photo_intro']

    
    def validate_start
        Video.video_types.keys.include?(self.video_type.downcase()) && self.way.include?(self.stop_at)
    end

    def validate_occasion
        Video.occasions.keys.include?(self.occasion.downcase()) && self.way.include?(self.stop_at)
    end

    def next_step
        curr_step = self.way.find_index self.stop_at
        return 0 if curr_step.nil?
        return self.way[curr_step+1]
    end

    def current_step
        curr_step = self.way.find_index self.stop_at
        return 0 if curr_step.nil?
        return self.way[curr_step]
    end

    def way 
        return SOLO_WAY if self.video_type == 'solo'
        return COLAB_WAY
    end
end

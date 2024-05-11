class VideoDestinataire < ApplicationRecord
  belongs_to :video

  enum :genre, { femme: 0, homme: 1, neutre: 2 }
end

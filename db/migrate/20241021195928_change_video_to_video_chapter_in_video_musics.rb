class ChangeVideoToVideoChapterInVideoMusics < ActiveRecord::Migration[7.1]
  def change
    remove_reference :video_musics, :video, foreign_key: true
    add_reference :video_musics, :video_chapter, null: false, foreign_key: true
  end
end

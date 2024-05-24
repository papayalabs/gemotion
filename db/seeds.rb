# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Chapter type, can be create in admin at a moment

family = ChapterType.create(name: 'Famille')
family.image.attach(
    io: File.open(Rails.root.join('app/assets/images/chapters/familiy.jpg')), 
    filename: 'familiy.jpg')

passion = ChapterType.create(name: 'Passion')
passion.image.attach(
        io: File.open(Rails.root.join('app/assets/images/chapters/passion.png')), 
        filename: 'passion.png')

rencontre = ChapterType.create(name: 'Rencontre')
rencontre.image.attach(
            io: File.open(Rails.root.join('app/assets/images/chapters/rencontre.webp')), 
            filename: 'rencontre.webp')
        
defi = ChapterType.create(name: 'Defi')
defi.image.attach(
                io: File.open(Rails.root.join('app/assets/images/chapters/challenge.jpeg')), 
                filename: 'challenge.jpeg')

ovni = Music.create(name: "L'Ovni")
ovni.music.attach(
    io: File.open(Rails.root.join('app/assets/musiques/ovni.mp3')), 
    filename: 'ovni.mp3')


tchikita = Music.create(name: "Tchikita")
tchikita.music.attach(
    io: File.open(Rails.root.join('app/assets/musiques/tchikita.mp3')), 
    filename: 'tchikita.mp3')

    bande = Music.create(name: "Bande")
bande.music.attach(
    io: File.open(Rails.root.join('app/assets/musiques/bande.mp3')), 
    filename: 'bande.mp3')


carpool = Dedicace.create(name: 'Carpool', description: "Description du thème de la dédicace finale. Ipsum dolor sit amet consectetur. Lorem ipsum dolor sit amet consectetur.")
carpool.video.attach(
        io: File.open(Rails.root.join('app/assets/videos/previews/specific_request.mp4')), 
        filename: 'carpool.mp4')

chanson = Dedicace.create(name: 'Chanson', description: "Description du thème de la dédicace finale. Ipsum dolor sit amet consectetur. Lorem ipsum dolor sit amet consectetur.")
chanson.video.attach(
            io: File.open(Rails.root.join('app/assets/videos/previews/theme_1.mp4')), 
            filename: 'chanson.mp4')
        
ondanse = Dedicace.create(name: 'On danse', description: "Description du thème de la dédicace finale. Ipsum dolor sit amet consectetur. Lorem ipsum dolor sit amet consectetur.")
ondanse.video.attach(
                io: File.open(Rails.root.join('app/assets/videos/previews/theme_2.mp4')), 
                filename: 'ondanse.mp4')
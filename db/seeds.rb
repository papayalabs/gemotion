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


chapter_vie = ChapterType.create(name: 'Sa vie ou leur vie')
chapter_vie.image.attach(
    io: File.open(Rails.root.join('app/assets/images/chapters/chapitre-vie.png')),
    filename: 'chapitre-vie.png')

chapter_famille = ChapterType.create(name: 'Famille')
chapter_famille.image.attach(
    io: File.open(Rails.root.join('app/assets/images/chapters/chapitre-famille.png')),
    filename: 'chapitre-famille.png')

chapter_passions = ChapterType.create(name: 'Passions')
chapter_passions.image.attach(
    io: File.open(Rails.root.join('app/assets/images/chapters/chapitre-passions.png')),
    filename: 'chapitre-passions.png')

chapter_rencontres = ChapterType.create(name: 'Rencontres')
chapter_rencontres.image.attach(
    io: File.open(Rails.root.join('app/assets/images/chapters/chapitre-rencontres.png')),
    filename: 'chapitre-rencontres.png')

chapter_defis = ChapterType.create(name: 'Défis')
chapter_defis.image.attach(
    io: File.open(Rails.root.join('app/assets/images/chapters/chapitre-defis.png')),
    filename: 'chapitre-defis.png')

chapter_aventure = ChapterType.create(name: 'Aventure')
chapter_aventure.image.attach(
    io: File.open(Rails.root.join('app/assets/images/chapters/chapitre-aventure.png')),
    filename: 'chapitre-aventure.png')

chapter_amis = ChapterType.create(name: 'Amis')
chapter_amis.image.attach(
    io: File.open(Rails.root.join('app/assets/images/chapters/chapitre-amis.png')),
    filename: 'chapitre-amis.png')


# family = ChapterType.create(name: 'Famille')
# family.image.attach(
#     io: File.open(Rails.root.join('app/assets/images/chapters/familiy.jpg')),
#     filename: 'familiy.jpg')

# passion = ChapterType.create(name: 'Passion')
# passion.image.attach(
#         io: File.open(Rails.root.join('app/assets/images/chapters/passion.png')),
#         filename: 'passion.png')

# rencontre = ChapterType.create(name: 'Rencontre')
# rencontre.image.attach(
#             io: File.open(Rails.root.join('app/assets/images/chapters/rencontre.webp')),
#             filename: 'rencontre.webp')

# defi = ChapterType.create(name: 'Defi')
# defi.image.attach(
#                 io: File.open(Rails.root.join('app/assets/images/chapters/challenge.jpeg')),
#                 filename: 'challenge.jpeg')

ami_1 = Music.create(name: "Ami 1")
ami_1.music.attach(
    io: File.open(Rails.root.join('app/assets/musiques/ami-1.mp3')),
    filename: 'ami-1.mp3')

ami_2 = Music.create(name: "Ami 2")
ami_2.music.attach(
    io: File.open(Rails.root.join('app/assets/musiques/ami-2.mp3')),
    filename: 'ami-2.mp3')

amour_1 = Music.create(name: "Amour 1")
amour_1.music.attach(
    io: File.open(Rails.root.join('app/assets/musiques/amour-1.mp3')),
    filename: 'amour-1.mp3')

amour_2 = Music.create(name: "Amour 2")
amour_2.music.attach(
    io: File.open(Rails.root.join('app/assets/musiques/amour-2.mp3')),
    filename: 'amour-2.mp3')

amour_3 = Music.create(name: "Amour 3")
amour_3.music.attach(
    io: File.open(Rails.root.join('app/assets/musiques/amour-3.mp3')),
    filename: 'amour-3.mp3')

amour_4 = Music.create(name: "Amour 4")
amour_4.music.attach(
    io: File.open(Rails.root.join('app/assets/musiques/amour-4.mp3')),
    filename: 'amour-4.mp3')

amour_5 = Music.create(name: "Amour 5")
amour_5.music.attach(
    io: File.open(Rails.root.join('app/assets/musiques/amour-5.mp3')),
    filename: 'amour-5.mp3')

amour_6 = Music.create(name: "Amour 6")
amour_6.music.attach(
    io: File.open(Rails.root.join('app/assets/musiques/amour-6.mp3')),
    filename: 'amour-6.mp3')

voyage_1 = Music.create(name: "Voyage 1")
voyage_1.music.attach(
    io: File.open(Rails.root.join('app/assets/musiques/voyage-1.mp3')),
    filename: 'voyage-1.mp3')

# ovni = Music.create(name: "L'Ovni")
# ovni.music.attach(
#     io: File.open(Rails.root.join('app/assets/musiques/ovni.mp3')),
#     filename: 'ovni.mp3')


# tchikita = Music.create(name: "Tchikita")
# tchikita.music.attach(
#     io: File.open(Rails.root.join('app/assets/musiques/tchikita.mp3')),
#     filename: 'tchikita.mp3')

# bande = Music.create(name: "Bande")
# bande.music.attach(
#     io: File.open(Rails.root.join('app/assets/musiques/bande.mp3')),
#     filename: 'bande.mp3')


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

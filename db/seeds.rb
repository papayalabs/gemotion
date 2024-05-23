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
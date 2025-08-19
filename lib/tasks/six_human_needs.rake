namespace :db do
  namespace :seed do
    desc "Seed the six human needs data"
    task six_human_needs: :environment do
      puts "Seeding Six Human Needs..."

      # Clear existing data if re-seeding - need to clear ways first due to foreign key constraint
      Way.delete_all
      SixHumanNeed.delete_all

# Create the six human needs based on Tony Robbins' framework
six_human_needs_data = [
  {
    name: "Certainty",
    description: "The need for security, stability, predictability, and comfort in life. This includes financial security, having routines, knowing what to expect, and feeling safe in your environment. People seek certainty through stable jobs, relationships, and familiar patterns.",
    order_position: 1
  },
  {
    name: "Uncertainty/Variety",
    description: "The need for surprise, adventure, change, and new experiences. This creates excitement and prevents boredom, helping us feel alive and stimulated. People fulfill this need through travel, trying new activities, taking risks, or embracing challenges that push them out of their comfort zones.",
    order_position: 2
  },
  {
    name: "Significance",
    description: "The need to feel unique, important, special, and valued. This includes seeking recognition, validation, achievement, and a sense that your life matters. People may pursue significance through career success, helping others, developing expertise, or standing out in meaningful ways.",
    order_position: 3
  },
  {
    name: "Love and Connection",
    description: "The need for human connection, intimacy, belonging, and acceptance. This encompasses romantic love, family bonds, friendships, community involvement, and feeling understood by others. It's about creating deep, meaningful relationships and feeling part of something larger than yourself.",
    order_position: 4
  },
  {
    name: "Growth",
    description: "The need for continuous improvement, learning, and personal development. This involves expanding your capabilities, acquiring new skills, overcoming challenges, and evolving as a person. Growth creates a sense of progress and achievement, with the understanding that progress equals happiness.",
    order_position: 5
  },
  {
    name: "Contribution",
    description: "The need to give back, serve others, and make a meaningful impact beyond yourself. This involves helping people you may not have direct personal connections to, supporting causes you believe in, volunteering, mentoring, or working toward something that benefits society as a whole.",
    order_position: 6
  }
]

# Create the records
six_human_needs_data.each do |need_data|
  need = SixHumanNeed.create!(need_data)
  puts "✓ Created: #{need.name}"
end

puts "\nSuccessfully created #{SixHumanNeed.count} human needs records"
    end
  end
end

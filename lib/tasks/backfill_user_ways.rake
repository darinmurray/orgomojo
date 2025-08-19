namespace :db do
  namespace :seed do
    desc "Backfill ways for existing users"
    task backfill_user_ways: :environment do
      puts "Backfilling ways for existing users..."

      users_updated = 0

      User.includes(:ways, :six_human_needs).find_each do |user|
        # Get the human needs this user doesn't have ways for yet
        existing_need_ids = user.ways.pluck(:six_human_need_id)
        missing_needs = SixHumanNeed.where.not(id: existing_need_ids)

        if missing_needs.any?
          missing_needs.each do |need|
            user.ways.create!(
              six_human_need: need,
              description: "Add your personal way of meeting the need for #{need.name.downcase}..."
            )
            puts "  ✓ Created way for #{user.email} -> #{need.name}"
          end
          users_updated += 1
        else
          puts "  → #{user.email} already has all ways"
        end
      end

      puts "\nBackfill complete! Updated #{users_updated} users."
      puts "Total users: #{User.count}"
      puts "Total ways: #{Way.count}"
    end
  end
end

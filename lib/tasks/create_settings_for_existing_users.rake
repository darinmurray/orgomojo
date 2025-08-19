namespace :settings do
  desc "Create settings for existing users"
  task create_for_existing_users: :environment do
    User.find_each do |user|
      unless user.setting
        user.create_setting
        puts "Created setting for user ##{user.id}"
      end
    end
  end
end

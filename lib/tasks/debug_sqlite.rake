namespace :db do
  desc "Debug SQLite database contents"
  task debug_sqlite: :environment do
    require 'sqlite3'
    
    sqlite_path = Rails.root.join('db', 'development.sqlite3')
    puts "🔍 Checking SQLite database at: #{sqlite_path}"
    puts "📁 File exists: #{File.exist?(sqlite_path)}"
    puts "📊 File size: #{File.size(sqlite_path) if File.exist?(sqlite_path)} bytes"
    
    if File.exist?(sqlite_path)
      sqlite_db = SQLite3::Database.new(sqlite_path.to_s)
      sqlite_db.results_as_hash = true
      
      # Get ALL tables (including Rails metadata)
      all_tables = sqlite_db.execute("SELECT name FROM sqlite_master WHERE type='table'")
      puts "📋 All tables in SQLite:"
      all_tables.each { |row| puts "  - #{row['name']}" }
      
      # Show what would be skipped
      skip_tables = ['schema_migrations', 'ar_internal_metadata', 'sqlite_sequence', 
                     'chat_sessions', 'chat_messages', 'user_responses', 'extracted_data_points']
      
      user_tables = all_tables.map { |row| row['name'] }
                             .reject { |name| skip_tables.include?(name) }
      
      puts "\n👤 Tables that WOULD be migrated:"
      user_tables.each { |name| puts "  - #{name}" }
      
      puts "\n🚫 Tables being skipped:"
      skip_tables.each { |name| puts "  - #{name}" }
      
      # Check record counts for tables we want to migrate
      user_tables.each do |table_name|
        begin
          count = sqlite_db.execute("SELECT COUNT(*) FROM #{table_name}").first[0]
          puts "\n📊 #{table_name}: #{count} records"
        rescue => e
          puts "\n❌ Error counting #{table_name}: #{e.message}"
        end
      end
      
      sqlite_db.close
    end
  end
end

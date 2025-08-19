namespace :db do
  desc "Migrate only core_values from SQLite to PostgreSQL"
  task migrate_core_values_only: :environment do
    require 'sqlite3'
    
    puts "🚀 Starting core_values-only migration..."
    
    # Connect to SQLite database
    sqlite_path = Rails.root.join('storage', 'development.sqlite3')
    sqlite_db = SQLite3::Database.new(sqlite_path.to_s)
    sqlite_db.results_as_hash = true
    
    # Get PostgreSQL connection
    postgres_conn = ActiveRecord::Base.connection
    
    # Check if core_values table exists in PostgreSQL
    unless postgres_conn.table_exists?('core_values')
      puts "❌ Table 'core_values' doesn't exist in PostgreSQL. You may need to run migrations first."
      sqlite_db.close
      exit 1
    end
    
    # Clear existing core_values
    puts "🗑️  Clearing existing core_values..."
    postgres_conn.execute("TRUNCATE TABLE core_values RESTART IDENTITY CASCADE")
    
    # Get all core_values from SQLite
    records = sqlite_db.execute("SELECT * FROM core_values")
    puts "📊 Found #{records.count} core_values to migrate"
    
    if records.any?
      success_count = 0
      
      # Insert records one by one
      records.each_with_index do |record, index|
        begin
          # Clean and prepare the record
          clean_record = record.transform_keys(&:to_s).transform_values { |v| v == "" ? nil : v }
          
          # Convert datetime strings
          clean_record.each do |key, value|
            if key.include?('_at') && value.is_a?(String)
              clean_record[key] = Time.parse(value)
            end
          end
          
          # Build the insert statement
          columns = clean_record.keys
          values = clean_record.values
          placeholders = (1..columns.length).map { |i| "$#{i}" }.join(', ')
          
          sql = "INSERT INTO core_values (#{columns.join(', ')}) VALUES (#{placeholders})"
          postgres_conn.exec_query(sql, 'SQL', values)
          
          success_count += 1
          
          # Progress indicator
          if (index + 1) % 10 == 0
            puts "  📈 Inserted #{index + 1}/#{records.count} core_values..."
          end
          
        rescue => e
          puts "  ❌ Error inserting core_value #{index + 1}: #{e.message}"
          puts "     Record: #{record.inspect}" if records.count < 20
        end
      end
      
      puts "✅ Successfully migrated #{success_count}/#{records.count} core_values"
      
      # Reset sequence
      if success_count > 0
        max_id = postgres_conn.select_value("SELECT MAX(id) FROM core_values")
        if max_id && max_id > 0
          sequence_name = postgres_conn.select_value("SELECT pg_get_serial_sequence('core_values', 'id')")
          if sequence_name
            postgres_conn.execute("SELECT setval('#{sequence_name}', #{max_id})")
            puts "🔄 Reset sequence #{sequence_name} to #{max_id}"
          end
        end
      end
      
      # Final verification
      final_count = postgres_conn.select_value("SELECT COUNT(*) FROM core_values")
      puts "📊 Final core_values count: #{final_count}"
      
    else
      puts "⚪ No core_values to migrate"
    end
    
    sqlite_db.close
    puts "🎉 Core_values migration completed!"
  end
end

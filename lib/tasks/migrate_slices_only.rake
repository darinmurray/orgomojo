namespace :db do
  desc "Migrate only slices from SQLite to PostgreSQL"
  task migrate_slices_only: :environment do
    require 'sqlite3'
    
    puts "🚀 Starting slices-only migration..."
    
    # Connect to SQLite database
    sqlite_path = Rails.root.join('storage', 'development.sqlite3')
    sqlite_db = SQLite3::Database.new(sqlite_path.to_s)
    sqlite_db.results_as_hash = true
    
    # Get PostgreSQL connection
    postgres_conn = ActiveRecord::Base.connection
    
    # Clear existing slices
    puts "🗑️  Clearing existing slices..."
    postgres_conn.execute("TRUNCATE TABLE slices RESTART IDENTITY CASCADE")
    
    # Get all slices from SQLite
    records = sqlite_db.execute("SELECT * FROM slices")
    puts "📊 Found #{records.count} slices to migrate"
    
    if records.any?
      success_count = 0
      
      # Insert records one by one using individual SQL statements
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
          
          sql = "INSERT INTO slices (#{columns.join(', ')}) VALUES (#{placeholders})"
          postgres_conn.exec_query(sql, 'SQL', values)
          
          success_count += 1
          
          # Progress indicator
          if (index + 1) % 10 == 0
            puts "  📈 Inserted #{index + 1}/#{records.count} slices..."
          end
          
        rescue => e
          puts "  ❌ Error inserting slice #{index + 1}: #{e.message}"
          puts "     Record: #{record.inspect}"
        end
      end
      
      puts "✅ Successfully migrated #{success_count}/#{records.count} slices"
      
      # Reset sequence
      if success_count > 0
        max_id = postgres_conn.select_value("SELECT MAX(id) FROM slices")
        if max_id && max_id > 0
          sequence_name = postgres_conn.select_value("SELECT pg_get_serial_sequence('slices', 'id')")
          if sequence_name
            postgres_conn.execute("SELECT setval('#{sequence_name}', #{max_id})")
            puts "🔄 Reset sequence #{sequence_name} to #{max_id}"
          end
        end
      end
      
      # Final verification
      final_count = postgres_conn.select_value("SELECT COUNT(*) FROM slices")
      puts "📊 Final slices count: #{final_count}"
      
    else
      puts "⚪ No slices to migrate"
    end
    
    sqlite_db.close
    puts "🎉 Slices migration completed!"
  end
end

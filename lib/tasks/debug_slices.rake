namespace :db do
  desc "Debug slices migration specifically"
  task debug_slices: :environment do
    require 'sqlite3'
    
    # Connect to SQLite database
    sqlite_path = Rails.root.join('storage', 'development.sqlite3')
    sqlite_db = SQLite3::Database.new(sqlite_path.to_s)
    sqlite_db.results_as_hash = true
    
    # Get PostgreSQL connection
    postgres_conn = ActiveRecord::Base.connection
    
    puts "🔍 Debugging slices migration..."
    
    # Check current state
    puts "📊 Current slices count in PostgreSQL: #{postgres_conn.select_value('SELECT COUNT(*) FROM slices')}"
    
    # Get slices from SQLite
    records = sqlite_db.execute("SELECT * FROM slices LIMIT 5")
    puts "📋 Sample SQLite slices records:"
    records.each { |r| puts "  #{r.inspect}" }
    
    # Check if pie_ids exist in PostgreSQL
    pie_ids = sqlite_db.execute("SELECT DISTINCT pie_id FROM slices").map { |r| r['pie_id'] }
    puts "\n🔗 Pie IDs referenced by slices: #{pie_ids}"
    
    existing_pies = postgres_conn.select_values("SELECT id FROM pies WHERE id IN (#{pie_ids.join(',')})")
    puts "✅ Existing pie IDs in PostgreSQL: #{existing_pies}"
    
    missing_pies = pie_ids - existing_pies
    if missing_pies.any?
      puts "❌ Missing pie IDs: #{missing_pies}"
    end
    
    # Try inserting one record manually
    puts "\n🧪 Testing single slice insert:"
    test_record = records.first
    if test_record
      begin
        clean_record = test_record.transform_keys(&:to_s).transform_values { |v| v == "" ? nil : v }
        
        # Convert datetime strings
        clean_record.each do |key, value|
          if key.include?('_at') && value.is_a?(String)
            begin
              clean_record[key] = Time.parse(value)
            rescue
              puts "  ⚠️  Could not parse datetime: #{key} = #{value}"
            end
          end
        end
        
        columns = clean_record.keys
        values = clean_record.values
        placeholders = (1..columns.length).map { |i| "$#{i}" }.join(', ')
        
        sql = "INSERT INTO slices (#{columns.join(', ')}) VALUES (#{placeholders})"
        puts "  SQL: #{sql}"
        puts "  Values: #{values.inspect}"
        
        postgres_conn.exec_query(sql, 'SQL', values)
        puts "  ✅ Test insert successful!"
        
        # Check if it's actually there
        count = postgres_conn.select_value("SELECT COUNT(*) FROM slices WHERE id = #{clean_record['id']}")
        puts "  📊 Record count after insert: #{count}"
        
        # Clean up test record
        postgres_conn.execute("DELETE FROM slices WHERE id = #{clean_record['id']}")
        
      rescue => e
        puts "  ❌ Test insert failed: #{e.message}"
        puts "  🔍 Full error: #{e.class}: #{e.message}"
      end
    end
    
    sqlite_db.close
  end
end

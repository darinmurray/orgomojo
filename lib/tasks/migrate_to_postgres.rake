namespace :db do
  desc "Migrate data from SQLite to PostgreSQL"
  task migrate_to_postgres: :environment do
    begin
      require "sqlite3"
    rescue LoadError
      puts "❌ sqlite3 gem not found. Please add it to your Gemfile:"
      puts "   gem 'sqlite3', '~> 1.4', group: :development"
      puts "   Then run: bundle install"
      exit 1
    end

    puts "🚀 Starting SQLite to PostgreSQL migration..."

    # Connect to SQLite database
    sqlite_path = Rails.root.join("storage", "development.sqlite3")
    unless File.exist?(sqlite_path)
      puts "❌ SQLite database not found at #{sqlite_path}"
      exit 1
    end

    sqlite_db = SQLite3::Database.new(sqlite_path.to_s)
    sqlite_db.results_as_hash = true

    # Get PostgreSQL connection
    postgres_conn = ActiveRecord::Base.connection

    # Tables to skip
    skip_tables = [ "schema_migrations", "ar_internal_metadata", "sqlite_sequence",
                   "chat_sessions", "chat_messages", "user_responses", "extracted_data_points" ]

    # Get all table names from SQLite (excluding Rails metadata and unwanted tables)
    tables = sqlite_db.execute("SELECT name FROM sqlite_master WHERE type='table'")
                     .map { |row| row["name"] }
                     .reject { |name| skip_tables.include?(name) }

    puts "📋 Found #{tables.count} tables to migrate: #{tables.join(', ')}"
    puts "⏩ Skipping: #{skip_tables.join(', ')}"

    # Disable foreign key checks temporarily
    postgres_conn.execute("SET session_replication_role = replica;") rescue nil

    tables.each do |table_name|
      puts "\n📦 Migrating table: #{table_name}"

      begin
        # Check if table exists in PostgreSQL
        unless postgres_conn.table_exists?(table_name)
          puts "  ⚠️  Table #{table_name} doesn't exist in PostgreSQL. Skipping..."
          next
        end

        # Get all records from SQLite
        records = sqlite_db.execute("SELECT * FROM #{table_name}")

        if records.any?
          puts "  📊 Found #{records.count} records"

          # Clear existing data in PostgreSQL table
          postgres_conn.execute("TRUNCATE TABLE #{table_name} RESTART IDENTITY CASCADE")

          # Insert records using ActiveRecord's insert_all for better compatibility
          success_count = 0
          batch_size = 100

          records.each_slice(batch_size) do |batch|
            begin
              # Convert records to proper format
              batch_data = batch.map do |record|
                # Convert hash keys to strings and handle nil values
                clean_record = record.transform_keys(&:to_s)
                                    .transform_values { |v| v == "" ? nil : v }

                # Convert datetime strings to proper format if needed
                clean_record.each do |key, value|
                  if key.include?("_at") && value.is_a?(String)
                    begin
                      clean_record[key] = Time.parse(value)
                    rescue
                      # Keep original value if parsing fails
                    end
                  end
                end

                clean_record
              end

              # Use ActiveRecord's insert_all method
              model_class = table_name.classify.constantize rescue nil

              if model_class
                # Use the model's insert_all method
                model_class.insert_all(batch_data, returning: false)
                success_count += batch_data.count
              else
                # Fallback to raw SQL with proper parameter binding
                batch_data.each do |record|
                  columns = record.keys
                  values = record.values
                  placeholders = (1..columns.length).map { |i| "$#{i}" }.join(", ")

                  sql = "INSERT INTO #{table_name} (#{columns.join(', ')}) VALUES (#{placeholders})"
                  postgres_conn.exec_query(sql, "SQL", values)
                  success_count += 1
                end
              end

              # Progress indicator
              if records.count > batch_size
                puts "    📈 Inserted #{success_count}/#{records.count} records..."
              end

            rescue => e
              puts "    ⚠️  Error inserting batch: #{e.message}"
              puts "    🔄 Trying individual inserts for this batch..."

              # Try individual inserts for this batch
              batch.each_with_index do |record, index|
                begin
                  clean_record = record.transform_keys(&:to_s)
                                      .transform_values { |v| v == "" ? nil : v }

                  # Convert datetime strings
                  clean_record.each do |key, value|
                    if key.include?("_at") && value.is_a?(String)
                      begin
                        clean_record[key] = Time.parse(value)
                      rescue
                        # Keep original value if parsing fails
                      end
                    end
                  end

                  columns = clean_record.keys
                  values = clean_record.values
                  placeholders = (1..columns.length).map { |i| "$#{i}" }.join(", ")

                  sql = "INSERT INTO #{table_name} (#{columns.join(', ')}) VALUES (#{placeholders})"
                  postgres_conn.exec_query(sql, "SQL", values)
                  success_count += 1

                rescue => individual_error
                  puts "      ❌ Failed to insert record: #{individual_error.message}"
                  if records.count < 20  # Only show record details for small tables
                    puts "         Record: #{clean_record.inspect}"
                  end
                end
              end
            end
          end

          puts "  ✅ Successfully migrated #{success_count}/#{records.count} records"

          # Reset sequence for id columns
          if postgres_conn.column_exists?(table_name, "id")
            max_id = postgres_conn.select_value("SELECT MAX(id) FROM #{table_name}")
            if max_id && max_id > 0
              sequence_name = postgres_conn.select_value(
                "SELECT pg_get_serial_sequence('#{table_name}', 'id')"
              )
              if sequence_name
                postgres_conn.execute("SELECT setval('#{sequence_name}', #{max_id})")
                puts "  🔄 Reset sequence #{sequence_name} to #{max_id}"
              end
            end
          end
        else
          puts "  ⚪ No records to migrate"
        end

      rescue => e
        puts "  ❌ Error migrating table #{table_name}: #{e.message}"
        puts "     #{e.backtrace.first}" if e.backtrace
      end
    end

    # Re-enable foreign key checks
    postgres_conn.execute("SET session_replication_role = DEFAULT;") rescue nil

    sqlite_db.close

    puts "\n🎉 Migration completed!"
    puts "\n📊 Final verification:"
    tables.each do |table|
      begin
        count = postgres_conn.select_value("SELECT COUNT(*) FROM #{table}")
        puts "   #{table}: #{count} records"
      rescue => e
        puts "   #{table}: Error counting - #{e.message}"
      end
    end

    puts "\n💡 Next steps:"
    puts "   1. Test your application thoroughly"
    puts "   2. Remove sqlite3 from Gemfile when satisfied"
    puts "   3. Delete db/development.sqlite3 when ready"
  end
end

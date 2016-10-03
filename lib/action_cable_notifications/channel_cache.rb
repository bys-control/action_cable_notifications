module ActionCableNotifications
  module Channel
    module Cache

      #
      # Updates server side cache of client side collections
      # XXX compute cache diff before sending to clients
      #
      def update_cache(packet)
        updated = false

        # Check if collection already exists
        new_collection = false
        if @collections[packet[:collection]].nil?
          @collections[packet[:collection]] = []
          new_collection = true
        end

        collection = @collections[packet[:collection]]

        case packet[:msg]
        when 'update_many'
          if !new_collection
            packet[:data].each do |record|
              current_record = collection.find{|c| c[:id]==record[:id]}
              if current_record
                new_record = current_record.merge(record)
                if new_record != current_record
                  current_record.merge!(record)
                  updated = true
                end
              end
            end
          end

        when 'upsert_many'
          if new_collection
            packet[:data].each do |record|
              collection.push record
            end
            updated = true
          else
            packet[:data].each do |record|
              current_record = collection.find{|c| c[:id]==record[:id]}
              if current_record
                new_record = current_record.merge(record)
                if new_record != current_record
                  current_record.merge!(record)
                  updated = true
                end
              else
                collection.push record
                updated = true
              end
            end
          end

        when 'create'
          record = collection.find{|c| c[:id]==packet[:id]}
          if !record
            @collections[packet[:collection]].push packet[:data]
            updated = true
          end

        when 'update'
          record = @collections[packet[:collection]].find{|c| c[:id]==packet[:id]}
          if record
            record.merge!(packet[:data])
            updated = true
          end

        when 'destroy'
          index = @collections[packet[:collection]].find_index{|c| c.id==packet[:id]}
          if index
            @collections[packet[:collection]].delete_at(index)
            updated = true
          end

        else
          updated = true
        end

        updated
      end

    end
  end
end

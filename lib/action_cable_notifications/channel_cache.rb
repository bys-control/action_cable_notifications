require 'action_cable_notifications/active_hash/active_hash.rb'

module ActionCableNotifications
  module Channel
    module Cache

      class ChannelCache < ActiveHash::Base
      end

      class ChannelCacheValidation < ActiveHash::Base
      end

      #
      # Validates packet before transmitting the message
      #
      # @param [Hash] packet Packet to be transmitted
      # @param [Hash] options Channels options used to validate the packet
      #
      # @return [Boolean] <description>
      #
      def validate_packet(packet, options = {})
        options = {
        }.merge(options)

        if packet[:msg].in? ['upsert_many', 'create', 'update', 'destroy']
          if packet[:msg].in? ['upsert_many']
            data = packet[:data]
          else
            data = Array(packet[:data].merge({id: packet[:id]}))
          end

          ChannelCacheValidation.data = data
          data = ChannelCacheValidation.scoped_collection(options[:scope])
          if data.present?
            data = data.map{|e| e.attributes} rescue []
            if packet[:msg].in? ['upsert_many']
              packet[:data] = data
            else
              packet[:data] = data.first
            end
            true
          else
            false
          end
        else
          true
        end

      end

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
          index = @collections[packet[:collection]].find_index{|c| c[:id]==packet[:id]}
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

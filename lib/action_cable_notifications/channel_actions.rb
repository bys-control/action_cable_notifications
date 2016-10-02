module ActionCableNotifications
  module Channel
    module Actions
      #
      # Fetch records from the DB and send them to the client
      #
      # @param [Hash] selector Specifies conditions that the registers should match
      #
      def fetch(data)
        # XXX: Check if the client is allowed to call the method

        params = data[:params] || {}

        # Get results using provided parameters and model configured scope
        results = data[:model].
                    select(params[:select]).
                    limit(params[:limit]).
                    where(params[:where] || {}).
                    scoped_collection(data[:model_options][:scope]).
                    to_a() rescue []

        response = { collection: data[:model].model_name.collection,
          msg: 'upsert_many',
          data: results
        }

        # Send data to the client
        transmit_packet response
      end

      #
      # Creates one record in the DB
      #
      def create(data)
        # XXX: Check if the client is allowed to call the method

        params = data[:params] || {}
        fields = params[:fields].except(:id)

        error = nil

        if fields.present?
          begin
            record = data[:model].create(fields)

            if !record.persisted?
              error = true
            end
          rescue Exception => e
            error = e.message
          end
        else
          error = "No fields were provided"
        end

        if error
          response = {
            collection: data[:model].model_name.collection,
            msg: 'error',
            cmd: 'create',
            error: error || record.errors.full_messages
          }

          # Send error notification to the client
          transmit response
        end

      end


      #
      # Update one record from the DB
      #
      def update(data)
        # XXX: Check if the client is allowed to call the method

        params = data[:params] || {}

        record = data[:model].find(params[:id]) rescue nil

        error = nil

        if record.present?
          begin
            record.update_attributes(params[:fields])
          rescue Exception => e
            error = e.message
          end
        else
          error = "There is no record with id: #{params[:id]}"
        end

        if error
          response = {
            collection: data[:model].model_name.collection,
            msg: 'error',
            cmd: 'update',
            error: error || record.errors.full_messages
          }

          # Send error notification to the client
          transmit response
        end

      end

      #
      # Remove records from the DB
      #
      def destroy(data)
        # XXX: Check if the client is allowed to call the method

        params = data[:params] || {}

        record = data[:model].find(params[:id]) rescue nil

        error = nil

        if record.present?
          begin
            record.destroy
          rescue Exception => e
            error = e.message
          end
        else
          error = "There is no record with id: #{params[:id]}"
        end

        if error
          response = { collection: data[:model].model_name.collection,
            msg: 'error',
            cmd: 'destroy',
            error: error || record.errors.full_messages
          }

          # Send error notification to the client
          transmit response
        end

      end

    end
  end
end

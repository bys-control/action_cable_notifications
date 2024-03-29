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
        begin
          temp_scope = data[:model_options][:scope].deep_dup || {}
          if (data[:model_options][:scope].is_a? Hash) && (data[:model_options][:scope][:where].is_a? Hash)
            #temp_scope = temp_scope.merge(params)
            temp_scope[:where].each{|k,v| v.is_a?(Proc) ? temp_scope[:where][k]=v.call() : nil }
          end
          results = data[:model].
                    select(params[:select] || []).
                    limit(params[:limit]).
                    where(params[:where] || {}).
                    scoped_collection(temp_scope).
                    to_a() rescue []

          response = {
            publication: data[:publication],
            msg: 'upsert_many',
            data: results
          }
        rescue Exception => e
          response = {
            publication: data[:publication],
            collection: data[:model].model_name.collection,
            msg: 'error',
            command: data[:command],
            error: e.message
          }
        end

        # Send data to the client
        transmit_packet response, data[:options]
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
            command: data[:command],
            error: error || record.errors.full_messages
          }

          # Send error notification to the client
          transmit_packet response
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
            record.update(params[:fields])
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
            command: data[:command],
            error: error || record.errors.full_messages
          }

          # Send error notification to the client
          transmit_packet response
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
            command: data[:command],
            error: error || record.errors.full_messages
          }

          # Send error notification to the client
          transmit_packet response
        end

      end

    end
  end
end

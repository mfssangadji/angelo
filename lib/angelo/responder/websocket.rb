module Angelo

  class WebsocketResponder < Responder

    class << self

      attr_writer :on_pong

      def on_pong
        @on_pong ||= ->(e){}
      end

    end

    def params
      @params ||= parse_query_string
      @params
    end

    def request= request
      @params = nil
      @request = request
      @websocket = @request.websocket
      handle_request
    end

    def handle_request
      begin
        if @response_handler
          Angelo.log @connection, @request, @websocket, :switching_protocols
          @bound_response_handler ||= @response_handler.bind @base
          @websocket.on_pong &WebsocketResponder.on_pong
          @bound_response_handler[@websocket]
        else
          raise NotImplementedError
        end
      rescue IOError => ioe
        warn "#{ioe.class} - #{ioe.message}"
        close_websocket
      rescue => e
        error e.message
        ::STDERR.puts e.backtrace
        begin
          @connection.close
        rescue Reel::StateError => rcse
          close_websocket
        end
      end
    end

    def close_websocket
      @websocket.close
      @base.websockets.delete @websocket
    end

  end

end

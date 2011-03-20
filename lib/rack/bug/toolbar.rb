module Rack
  class Bug
    class Toolbar
      include Render

      MIME_TYPES = ["text/html", "application/xhtml+xml"]

      def initialize(app)
        @app = app
      end

      attr_accessor :railsbug_enabled
      
      def call(env)
        @env = env
        @env["rack-bug.panels"] = []

        Rack::Bug.enable
        status, headers, body = builder.call(@env)
        Rack::Bug.disable
        

        @response = Rack::Response.new(body, status, headers)

        if railsbug_enabled
          inject_railsbug_headers
        elsif response_type_okay_to_modify?
          inject_toolbar 
        end
        
        return @response.to_a
      end

      def inject_railsbug_headers
        data = collect_railsbug_data

        i = 0
        begin
          @response["X-RailsBug-#{i+=1}"] = data.slice!(0, 8000)
        end while data.length > 0
      end
      
      def collect_railsbug_data
        @env['rack-bug.panels'].select {|panel| 
          panel.respond_to?(:to_hash)
        }.reverse.inject({}){ |response_hash, panel| 
          response_hash[panel.name]=panel.to_hash
          response_hash
        }.to_json
      end


      def response_type_okay_to_modify?
        content_type, charset = @response.content_type.split(";")
        @response.ok? && MIME_TYPES.include?(content_type)
      end

      def builder
        builder = Rack::Builder.new

        @env["rack-bug.panel_classes"].each do |panel_class|
          builder.use panel_class
        end

        builder.run @app

        return builder
      end

      def inject_toolbar
        full_body = @response.body.join
        full_body.sub! /<\/body>/, render + "</body>"

        @response["Content-Length"] = full_body.size.to_s

        # Ensure that browser does
        @response["Etag"] = ""
        @response["Cache-Control"] = "no-cache"

        @response.body = [full_body]
      end

      def render
        render_template("toolbar", :panels => @env["rack-bug.panels"].reverse)
      end

    end

  end
end

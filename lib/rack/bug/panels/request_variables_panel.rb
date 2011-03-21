module Rack
  class Bug

    class RequestVariablesPanel < Panel

      def name
        "request_variables"
      end

      def before(env)
        @env = env
      end

      def heading
        "Rack Env"
      end
        

      def content
        render_template "panels/request_variables", :sections => sections
      end

      def to_hash
        {:title => controller_and_action, :sections => clean_hash(sections)}
      end


    private
      def sort(hash)
        hash.sort_by { |k, v| k.to_s }
      end

      def sections
        _sections = {}
        _sections["GET"] = sort(@request.GET) if @request.GET.any?
        _sections["POST"] = sort(@request.GET) if @request.POST.any?
        _sections["Session"] = sort(@request.env["rack.session"]) if @request.env["rack.session"] && @request.env["rack.session"].any?
        _sections["Cookies"] = sort(@request.env["rack.request.cookie_hash"]) if @request.env["rack.request.cookie_hash"] && @request.env["rack.request.cookie_hash"].any?
        server, rack = split_and_filter_env(@env)
        _sections["SERVER VARIABLES"] = sort(server)
        _sections["Rack ENV"] = sort(rack)
        _sections
      end
      
      def clean_hash(hash)
        Hash[*hash.map{|k,v| [k, clean_var(v)]}.flatten(1)]
      end


      def clean_var(v)
        case v
        when Hash
          clean_hash(v)
        when Array
          v.map{|a| clean_var(a)}
        else
          v.to_s
        end
      end

      def controller_and_action
        parts = [
          @env['action_dispatch.request.parameters']['controller'],
          @env['action_dispatch.request.parameters']['action']
        ].compact

        parts.empty? ? 'Rails environment' : parts.join('#')
      end

      def split_and_filter_env(env)
        server, rack = {}, {}
        env.each do |k,v|
          if k.index("rack.") == 0
            rack[k] = v
          elsif k.index("rack-bug.") == 0
            #don't output the rack-bug variables - especially secret_key
          else
            server[k] = v
          end
        end
        return server, rack
      end

    end

  end
end

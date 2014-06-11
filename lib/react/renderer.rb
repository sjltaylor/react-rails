require 'connection_pool'
require 'digest'

module React
  class Renderer

    cattr_accessor :pool

    def self.setup!(react_js, components_js, args={})
      args.assert_valid_keys(:size, :timeout)
      @@react_js = react_js
      @@components_js = components_js

      @@pool.shutdown{} if @@pool
      @@pool = ConnectionPool.new(:size => args[:size]||10, :timeout => args[:timeout]||20) { self.new }
    end

    def self.render(component, args={})
      @@pool.with do |renderer|
        renderer.render(component, args)
      end
    end

    def context
      combined_js = self.class.combined_js
      #combined_js_digest = Digest::SHA1.new.tap{|d| d << combined_js }

      #return @context if @previous_combined_js_digest == combined_js_digest
      #@previous_combined_js_digest = combined_js_digest
      #@context = ExecJS.compile(combined_js)
      ExecJS.compile(combined_js)
    end

    def render(component, args={})
      jscode = <<-JS
        function() {
          return React.renderComponentToString(#{component}(#{args.to_json}));
        }()
      JS

      context.eval(jscode).html_safe
    # What should be done here? If we are server rendering, and encounter an error in the JS code,
    # then log it and continue, which will just render the react ujs tag, and when the browser tries
    # to render the component it will most likely encounter the same error and throw to the browser
    # console for a better debugging experience.
    rescue ExecJS::ProgramError => e
      ::Rails.logger.error "[React::Renderer] #{e.message}"
    end

    protected

    def self.combined_js
      c = <<-CODE
        var global = global || this;
        #{@@react_js};
        React = global.React;
        #{@@components_js};
      CODE

      ::Rails.logger.info "COMBINED JS SHA: #{Digest::SHA1.new.tap{|d| d << c }.to_s}"
      c
    end
  end
end

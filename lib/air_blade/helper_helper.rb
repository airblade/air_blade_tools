module AirBlade
  module HelperHelper

    # http://drawohara.com/post/23559471  (modified a little by me).
    #
    # Makes helpers available inside your controllers without
    # polluting the namespace.  You can call +pan_helper+ either
    # with a block or as an attribute.  E.g.
    #
    #   flash[:info] = "Discovered #{pan_helper.pluralize @primes.count, 'prime'}."
    #   flash[:info] = "Discovered #{pan_helper { pluralize @primes.count, 'prime'} }."
    #
    # Note this excludes application helpers (i.e. in app/helpers/).
    def pan_helper &block
      unless defined?(@helper)
        controller = self
        @helper = Object.new.instance_eval do
          @controller = controller
          helpers = ActionView::Helpers
          helpers.constants.grep(/Helper/i).each{|c| puts c; extend helpers.const_get(c)}
          self
        end
      end
      block ? @helper.instance_eval(&block) : @helper
    end

  end
end

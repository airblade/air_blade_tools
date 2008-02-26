module AirBlade
  module LayoutHelper

    # http://inventivelabs.com.au:80/weblog/post/providing-default-content-in-rails-layouts
    #
    # Use in a layout to provide default content that views may override.
    # For example:
    #
    #  <% default_content_for :sidebar do %>
    #    <p>This is the default sidebar content!  Etc.</p>
    #  <% end %>
    #
    # Then a view rendering inside the layout may declare its own sidebar content
    # like this:
    #
    #   <% content_for :sidebar do %>
    #     <p>View-specific sidebar content.</p>
    #   <% end %>
    def default_content_for(name, &block)
      out = eval "yield #{name.to_sym}", block.binding
      concat(out || capture(&block), block.binding)
    end

  end
end

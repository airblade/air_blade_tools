# http://drawohara.com/post/23559471  (modified a little by me).
# See documentation for +pan_helper+ method.
ActionController::Base.send :include, AirBlade::HelperHelper
ActionController::Base.send :include, AirBlade::LayoutHelper
ActionController::Base.send :protected, :pan_helper
ActiveRecord::Migration.send :include, AirBlade::MigrationHelper

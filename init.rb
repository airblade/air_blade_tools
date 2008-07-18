# http://drawohara.com/post/23559471  (modified a little by me).
# See documentation for +pan_helper+ method.
ActionController::Base.send :include, AirBlade::HelperHelper
ActionController::Base.send :include, AirBlade::LayoutHelper
ActionController::Base.send :protected, :pan_helper

# Foreign key constraints.
ActiveRecord::Migration.send :extend, AirBlade::MigrationHelper::SchemaStatements
ActiveRecord::ConnectionAdapters::TableDefinition.send :include, AirBlade::MigrationHelper::SchemaDefinitions
ActiveRecord::ConnectionAdapters::SchemaStatements.send :include, AirBlade::MigrationHelper::SchemaStatements

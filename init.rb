# Foreign key constraints.
ActiveRecord::Migration.send :extend, AirBlade::Migrations::SchemaStatements
ActiveRecord::ConnectionAdapters::TableDefinition.send :include, AirBlade::Migrations::SchemaDefinitions
ActiveRecord::ConnectionAdapters::SchemaStatements.send :include, AirBlade::Migrations::SchemaStatements

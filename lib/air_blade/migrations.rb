require 'active_support'

# Inspired by:
# * Advanced Rails Recipe 8.
# * Foreign Key Migrations plugin, by RedHill Consulting
#   http://www.redhillonrails.org/foreign_key_migrations.html
module AirBlade
  module Migrations

    def constraint_name(table, column)
      "fk_#{table}_#{column}"
    end

    # Options:
    #  :to_table
    #  :on_delete => :cascade | :nullify | :restrict (default)
    #  :on_update => :cascade | :nullify | :restrict
    #
    # Note :ondelete => :nullify only works if foreign key column in question can be null.
    def foreign_key_constraint(from_table, from_column, options = {})
      to_table = options[:to_table] || from_column.to_s[/^(.+)_id$/, 1].tableize
      on_delete = case options[:on_delete]
                  when :cascade; 'cascade'
                  when :nullify; 'set null'
                  end
      on_update = case options[:on_update]
                  when :cascade;  'cascade'
                  when :nullify;  'set null'
                  when :restrict; 'restrict'
                  end
      cmd = [ "constraint #{constraint_name from_table, from_column}",
              "foreign key (#{from_column})",
              "references #{quote_table_name to_table}(id)",
      ]
      cmd << "on delete #{on_delete}" if on_delete
      cmd << "on update #{on_update}" if on_update
      cmd.join(' ')
    end


    # Makes +add_foreign_key+ and +drop_foreign_key+ available in migrations
    # where you might use +add_index+.
    module SchemaStatements
      include AirBlade::Migrations

      # When +create_table+ is called, we store the table name so we can
      # use it when defining foreign key constraints.
      def self.included(base)
        base.alias_method_chain :create_table, :storing_name
        mattr_accessor :table_name
        @@table_name = ''
      end

      # Holds onto the name of the table being created.
      def create_table_with_storing_name(table_name, options = {}, &block)
        @@table_name = table_name
        create_table_without_storing_name table_name, options, &block
        AirBlade::Migrations::SchemaDefinitions.foreign_keys = []
      end

      # Sets a foreign key constraint.
      # Use in a migration where you might use +add_index+.
      def add_foreign_key(from_table, from_column, options = {})
        execute [ "alter table #{quote_table_name from_table}",
                  "add #{foreign_key_constraint from_table, from_column, options}"
        ].join(' ')
      end

      # Drops a foreign key constraint.
      # Use in a migration where you might use +add_index+.
      def drop_foreign_key(from_table, from_column)
        execute [ "alter table #{quote_table_name from_table}",
                  "drop foreign key #{constraint_name from_table, from_column}"
        ].join(' ')
      end
    end


    # Use within a +create_table+ block.
    # Defines a foreign key constraint for every call to +references+,
    # unless the reference is polymorphic.
    module SchemaDefinitions
      include AirBlade::Migrations

      def self.included(base)
        base.alias_method_chain :references, :foreign_key
        base.alias_method_chain :to_sql, :foreign_keys
        mattr_accessor :foreign_keys
        @@foreign_keys = []
      end

      # Holds onto the foreign key column when another table is referenced.
      def references_with_foreign_key(*args)
        # Don't pop, unlike extract_options!, because we need to leave *args intact.
        options = args.last.is_a?(::Hash) ? args.last : {}
        polymorphic = options.has_key? :polymorphic

        references_without_foreign_key *args

        # Now we discard any options.
        options = args.extract_options!  

        unless polymorphic
          args.each do |column|
            @@foreign_keys << ["#{column}_id", options]
          end
        end
      end

      # Writes out the foreign key constraints after writing out the table definition.
      def to_sql_with_foreign_keys
        from_table = AirBlade::Migrations::SchemaStatements.table_name
        fks = @@foreign_keys.map{ |column, options| foreign_key_constraint from_table, column, options }
        [ to_sql_without_foreign_keys, fks ].reject{ |x| x.blank? }.join ', '
      end
    end


  end
end

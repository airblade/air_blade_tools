require 'active_support'

# Inspired by:
# * Advanced Rails Recipe 8.
# * Foreign Key Migrations plugin, by RedHill Consulting
#   http://www.redhillonrails.org/foreign_key_migrations.html
module AirBlade
  module Migrations

    module SchemaStatements
      # Sets a foreign key constraint.
      # Use in a migration where you might use +add_index+.
      def add_foreign_key(from_table, from_column, to_table)
        execute %(alter table #{from_table}
                  add constraint #{constraint_name(from_table, from_column)}
                  foreign key (#{from_column})
                  references #{to_table}(id))
      end

      # Drops a foreign key constraint.
      # Use in a migration where you might use +add_index+.
      def drop_foreign_key(from_table, from_column)
        execute %(alter table #{from_table}
                  drop foreign key #{constraint_name(from_table, from_column)})
      end

      def constraint_name(table, column)
        "fk_#{table}_#{column}"
      end


      # When +create_table+ is called, we store the table name so we can
      # use it when defining foreign key constraints.
      def self.included(base)
        base.alias_method_chain :create_table, :storing_name
        mattr_accessor :table_name
        @@table_name = ''
      end

      def create_table_with_storing_name(table_name, options = {}, &block)
        @@table_name = table_name
        create_table_without_storing_name table_name, options, &block
        AirBlade::Migrations::SchemaDefinitions.foreign_keys = []
      end
    end


    # Use within a +create_table+ block.
    # Defines a foreign key constraint for every call to +references+,
    # unless the reference is polymorphic.
    module SchemaDefinitions
      def self.included(base)
        base.alias_method_chain :references, :foreign_key
        base.alias_method_chain :to_sql, :foreign_keys
        mattr_accessor :foreign_keys
        @@foreign_keys = []
      end

      def references_with_foreign_key(*args)
        # Don't pop, unlike extract_options!, because we need to leave *args intact.
        options = args.last.is_a?(::Hash) ? args.last : {}
        polymorphic = options.has_key? :polymorphic

        references_without_foreign_key *args

        # Now we discard any options.
        args.extract_options!  
        unless polymorphic
          args.each do |col|
            # FIXME: proper table name
            @@foreign_keys << { :from_column => "#{col}_id", :to_table => "#{col}s" }
          end
        end
      end

      def to_sql_with_foreign_keys
        fks = @@foreign_keys.map{ |fk| foreign_key_constraint(fk[:from_column], fk[:to_table]) }
        [to_sql_without_foreign_keys, fks].reject{ |x| x.blank? } * ', '
      end

      def foreign_key_constraint(from_column, to_table)
        from_table = AirBlade::Migrations::SchemaStatements.table_name
        %(constraint #{constraint_name(from_table, from_column)}
          foreign key (#{from_column})
          references #{to_table}(id))
      end

      def constraint_name(table, column)
        "fk_#{table}_#{column}"
      end
    end

  end
end

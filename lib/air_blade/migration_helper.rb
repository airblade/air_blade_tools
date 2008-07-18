# Advanced Rails Recipe 8.
module AirBlade
  module MigrationHelper

    def fk(from_table, from_column, to_table)
      execute %(alter table #{from_table}
                add constraint #{constraint_name(from_table, from_column)}
                foreign key (#{from_column})
                references #{to_table}(id))
    end

    def drop_fk(from_table, from_column)
      execute %(alter table #{from_table}
                drop foreign key #{constraint_name(from_table, from_column)})
    end

    def constraint_name(table, column)
      "fk_#{table}_#{column}"
    end

  end
end

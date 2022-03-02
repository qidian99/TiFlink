package org.tikv.tiflink;

import org.tikv.flink.TiFlinkApp;

public class MoneyExample {
  public static void main(final String[] args) throws Exception {
    final TiFlinkApp.Builder appBuilder =
        TiFlinkApp.newBuilder()
            .setJdbcUrl("jdbc:mysql://root@localhost:4000/test") // Please make sure the user has correct permission
            .setQuery(String.format("select w.id as id, w.name as name, sum(c.ratio * h.amount) as richness from worker w inner join holding h on w.id = h.w_id inner join currency c on h.c_id = c.id group by w.name, w.id"))
                            // .setColumnNames("a", "b", "c", "d") // Override column names inferred from the query
            // .setPrimaryKeys("a") // Specify the primary key columns, defaults to the first column
            // .setDefaultDatabase("test") // Default TiDB database to use, defaults to that specified by JDBC URL
            .setTargetTable("richness") // TiFlink will automatically create the table if not exist
            // .setTargetTable("test", "author_posts") // It is possible to sepecify the full table path
            .setParallelism(2) // Parallelism of the Flink Job
            .setCheckpointInterval(1000) // Checkpoint interval in milliseconds. This interval determines data refresh rate
            .setDropOldTable(true) // If TiFlink should drop old target table on start
            .setForceNewTable(true); // If to throw an error if the target table already exists
    try (final TiFlinkApp app = appBuilder.build()) {
      app.start();
    }
  }
}

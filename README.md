# TiFlink

An experimental materialized view solution based on TiDB/TiKV and Flink with strong consistency support.

## Description

TiFlink is intended to provide an easy to use materialized view on TiDB.
It's mainly based on Flink and supports Flink StreamSQL syntax. You will only need to
specify a SQL query and a JDBC URL to your TiDB, `TiFlinkApp` will take care of
the rest.

TiFlink has no external dependencies other than TiDB/TiKV and Flink so that there
is no need to maintain Kafka and TiCDC clusters. It will read/write directly from/to TiKV
with parallel tasks, which should maximum the throughput with low latency.
TiFlink will also first fully snapshot existing source tables and then automatically
turn to CDC stream processing.

TiFlink is designed to provide strong consistency. It makes use of
raw transaction information and global timestamps from TiKV to achieve "Stale Snapshot Isolation",
which means everytime when you query the target table, you will see a consistent snapshot of
the materialized view in some past time. Thus, ACID of transactions on source tables as well as
linearizability are kept. For details, please refer to the [draft doc](https://internals.tidb.io/t/topic/124).

TiFlink is currently in early preview and not production ready.
Bug reports and contributions are welcome.

## Key Features

1. Strong consistency
2. Minimum deployment dependencies
3. Read/Write directly from/To TiKV
4. Unified Batch/Stream processing 
5. Easy to use

## Dependencies

* Java >= 11
* TiDB/TiKV >= 5.0.0
* Flink >= 1.13.0
* tikv/client-java >= 3.2.0 (**Pending release**)

## Usage

See [TiFlinkExample.java](./examples/src/main/java/org/tikv/tiflink/TiFlinkExample.java)

```java
TiFlinkApp.newBuilder()
   .setJdbcUrl("jdbc:mysql://root@localhost:4000/test") // Please make sure the user has correct permission
   .setQuery(
       "select id, "
           + "first_name, "
           + "last_name, "
           + "email, "
           + "(select count(*) from posts where author_id = authors.id) as posts "
           + "from authors")
   // .setColumnNames("a", "b", "c", "d") // Override column names inferred from the query
   // .setPrimaryKeys("a") // Specify the primary key columns, defaults to the first column
   // .setDefaultDatabase("test") // Default TiDB database to use, defaults to that specified by JDBC URL
   .setTargetTable("author_posts") // TiFlink will automatically create the table if not exist
   // .setTargetTable("test", "author_posts") // It is possible to sepecify the full table path
   .setParallelism(3) // Parallelism of the Flink Job
   .setCheckpointInterval(1000) // Checkpoint interval in milliseconds. This interval determines data refresh rate
   .setDropOldTable(true) // If TiFlink should drop old target table on start
   .setForceNewTable(true) // If to throw an error if the target table already exists
   .build()
   .start(); // Start the app
```

## Table Structures

### authors

```sql
CREATE TABLE IF NOT EXISTS authors (
    id int not null auto_increment,
    first_name varchar(255),
    last_name varchar(255),
    email varchar(255),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS posts (
    id int not null auto_increment,
    author_id int,
    PRIMARY KEY (id),
    foreign key aid (author_id) references authors(id) on delete cascade 
);

insert into authors values (1, 'Dian', 'Qi', 'email@example.com');
insert into authors values (2, 'Naid', 'Iq', 'liame@example.com');
```

## Problem

1. Full Data Sync will block on checkpoint lock if source is emitting records while checkpointing is in progresss. 
2. Table region issue in Tiup playground

SPLIT TABLE table_name [INDEX index_name] BETWEEN (lower_value) AND (upper_value) REGIONS region_num
SPLIT TABLE authors BETWEEN (1) AND (300) REGIONS 1;

```sql
CREATE TABLE IF NOT EXISTS `authors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(50),
  `last_name` varchar(50),
  `email` varchar(100),
  `birthdate` date,
  `added` timestamp DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) partition by hash(id) partitions 2;

CREATE TABLE IF NOT EXISTS `posts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `author_id` int(11),
  `title` varchar(255),
  `description` varchar(500),
  `content` text,
  `date` date,
  PRIMARY KEY (`id`)
) partition by hash(id) partitions 2;

CREATE TABLE IF NOT EXISTS `author_posts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(50),
  `last_name` varchar(50),
  `email` varchar(100),
  `posts` bigint(32),
  PRIMARY KEY (`id`)
) partition by hash(id) partitions 2;

```
```bash
mysql> show table authors regions\G
*************************** 1. row ***************************
           REGION_ID: 119
           START_KEY: t_141_
             END_KEY: t_142_
           LEADER_ID: 120
     LEADER_STORE_ID: 1
               PEERS: 120
          SCATTERING: 0
       WRITTEN_BYTES: 0
          READ_BYTES: 0
APPROXIMATE_SIZE(MB): 1
    APPROXIMATE_KEYS: 0
*************************** 2. row ***************************
           REGION_ID: 121
           START_KEY: t_142_
             END_KEY: t_145_
           LEADER_ID: 122
     LEADER_STORE_ID: 1
               PEERS: 122
          SCATTERING: 0
       WRITTEN_BYTES: 927
          READ_BYTES: 0
APPROXIMATE_SIZE(MB): 1
    APPROXIMATE_KEYS: 0
2 rows in set (0.00 sec)
```


3. ScanRow return empty set when parallelism = 1

TiKV regions error
## TODO

- [ ] Non-Integer and compound primary key support
- [ ] Better Flink task to TiKV Region mapping  
- [ ] Automatically clean up uncommitted transaction on restart
- [ ] Unit tests


# License

See [LICENSE](./LICENSE).

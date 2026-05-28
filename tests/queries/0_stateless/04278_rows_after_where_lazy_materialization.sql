-- Tags: no-random-settings, no-random-merge-tree-settings

DROP TABLE IF EXISTS test_rows_after_where_lazy_materialization;

CREATE TABLE test_rows_after_where_lazy_materialization
(
    k UInt64,
    payload String
)
ENGINE = MergeTree
ORDER BY k
SETTINGS index_granularity = 128;

INSERT INTO test_rows_after_where_lazy_materialization
SELECT number, repeat('x', 100)
FROM numbers(1000);

SELECT count() > 0
FROM
(
    EXPLAIN PLAN
    SELECT payload
    FROM test_rows_after_where_lazy_materialization
    WHERE k % 2 = 0
    ORDER BY k
    LIMIT 10
    SETTINGS
        query_plan_optimize_lazy_materialization = 1,
        query_plan_max_limit_for_lazy_materialization = 10,
        query_plan_optimize_prewhere = 0,
        optimize_read_in_order = 0,
        optimize_move_to_prewhere = 0
)
WHERE explain LIKE '%LazilyRead%';

SELECT payload
FROM test_rows_after_where_lazy_materialization
WHERE k % 2 = 0
ORDER BY k
LIMIT 10
FORMAT Null
SETTINGS
    query_plan_optimize_lazy_materialization = 1,
    query_plan_max_limit_for_lazy_materialization = 10,
    query_plan_optimize_prewhere = 0,
    optimize_read_in_order = 0,
    optimize_move_to_prewhere = 0,
    log_comment = '04278_rows_after_where_lazy_materialization';

SYSTEM FLUSH LOGS query_log;

SELECT ProfileEvents['RowsAfterWhere']
FROM system.query_log
WHERE current_database = currentDatabase()
    AND type = 'QueryFinish'
    AND log_comment = '04278_rows_after_where_lazy_materialization'
ORDER BY event_time_microseconds DESC
LIMIT 1;

DROP TABLE test_rows_after_where_lazy_materialization;

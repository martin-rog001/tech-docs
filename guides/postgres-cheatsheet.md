# PostgreSQL Cheatsheet

## Essential Features

### Data Types

**String Types**
- `CHAR(n)` - Fixed-length string
- `VARCHAR(n)` - Variable-length string with limit
- `TEXT` - Variable unlimited length string
- `CITEXT` - Case-insensitive text (requires extension)

**Numeric Types**
- `SMALLINT` - 2-byte integer (-32768 to 32767)
- `INTEGER` - 4-byte integer (-2147483648 to 2147483647)
- `BIGINT` - 8-byte integer
- `DECIMAL(p,s)` / `NUMERIC(p,s)` - Exact numeric with precision
- `REAL` - 4-byte floating point
- `DOUBLE PRECISION` - 8-byte floating point
- `SERIAL` - Auto-incrementing integer
- `BIGSERIAL` - Auto-incrementing bigint

**Date and Time Types**
- `DATE` - Date (no time)
- `TIME` - Time (no date)
- `TIMESTAMP` - Date and time (no timezone)
- `TIMESTAMPTZ` - Date and time with timezone
- `INTERVAL` - Time interval

**Boolean Type**
- `BOOLEAN` - TRUE, FALSE, or NULL

**JSON Types**
- `JSON` - JSON data (stored as text, validated)
- `JSONB` - Binary JSON (faster, indexable, recommended)

**Array Types**
- `type[]` - Array of any type
```sql
INT[], TEXT[], NUMERIC[]
```

**UUID Type**
- `UUID` - Universally unique identifier

**Network Types**
- `INET` - IPv4 or IPv6 address
- `CIDR` - IPv4 or IPv6 network
- `MACADDR` - MAC address

**Geometric Types**
- `POINT` - Point in 2D space
- `LINE` - Infinite line
- `CIRCLE` - Circle
- `POLYGON` - Polygon

**Range Types**
- `INT4RANGE` - Range of integers
- `TSRANGE` - Range of timestamps
- `DATERANGE` - Range of dates

### Basic CRUD Operations

**CREATE**
```sql
-- Create database
CREATE DATABASE myapp;

-- Create table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL,
    tags TEXT[],
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**INSERT**
```sql
-- Single insert
INSERT INTO users (username, email)
VALUES ('john_doe', 'john@example.com');

-- Multiple insert
INSERT INTO users (username, email) VALUES
('alice', 'alice@example.com'),
('bob', 'bob@example.com');

-- Insert with RETURNING
INSERT INTO users (username, email)
VALUES ('jane', 'jane@example.com')
RETURNING id, created_at;
```

**SELECT**
```sql
-- Select all
SELECT * FROM users;

-- Select specific columns
SELECT username, email FROM users;

-- With WHERE clause
SELECT * FROM users WHERE id = 1;

-- With ORDER BY
SELECT * FROM users ORDER BY created_at DESC;

-- With LIMIT and OFFSET
SELECT * FROM users LIMIT 10 OFFSET 20;

-- DISTINCT
SELECT DISTINCT username FROM users;
```

**UPDATE**
```sql
-- Update single row
UPDATE users SET email = 'newemail@example.com' WHERE id = 1;

-- Update multiple rows
UPDATE users SET created_at = NOW() WHERE created_at IS NULL;

-- Update with RETURNING
UPDATE users SET email = 'new@example.com' WHERE id = 1
RETURNING email, username;
```

**DELETE**
```sql
-- Delete specific rows
DELETE FROM users WHERE id = 1;

-- Delete with RETURNING
DELETE FROM users WHERE id = 1 RETURNING *;

-- Delete all rows
DELETE FROM users;

-- Truncate (faster, resets sequences)
TRUNCATE TABLE users RESTART IDENTITY CASCADE;
```

### Constraints

**PRIMARY KEY**
```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY
);

-- Composite primary key
CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    PRIMARY KEY (order_id, product_id)
);
```

**FOREIGN KEY**
```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE
);

-- Named foreign key
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT,
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**UNIQUE**
```sql
CREATE TABLE users (
    email VARCHAR(100) UNIQUE
);

-- Composite unique
CREATE TABLE products (
    name VARCHAR(100),
    category VARCHAR(50),
    UNIQUE (name, category)
);
```

**NOT NULL**
```sql
CREATE TABLE users (
    username VARCHAR(50) NOT NULL
);
```

**CHECK**
```sql
CREATE TABLE products (
    price NUMERIC CHECK (price > 0),
    quantity INT CHECK (quantity >= 0)
);

-- Named check constraint
CREATE TABLE users (
    age INT,
    CONSTRAINT age_check CHECK (age >= 18 AND age <= 120)
);
```

**DEFAULT**
```sql
CREATE TABLE users (
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**EXCLUSION**
```sql
-- Prevent overlapping ranges (requires btree_gist extension)
CREATE TABLE reservations (
    room_id INT,
    during TSRANGE,
    EXCLUDE USING GIST (room_id WITH =, during WITH &&)
);
```

### Indexes

**B-tree Index (Default)**
```sql
CREATE INDEX idx_username ON users(username);

-- Unique index
CREATE UNIQUE INDEX idx_email ON users(email);

-- Composite index
CREATE INDEX idx_name ON users(last_name, first_name);

-- Partial index
CREATE INDEX idx_active_users ON users(username) WHERE status = 'active';

-- Expression index
CREATE INDEX idx_lower_email ON users(LOWER(email));
```

**GIN Index (for arrays, JSONB, full-text)**
```sql
-- For JSONB
CREATE INDEX idx_metadata ON users USING GIN(metadata);

-- For arrays
CREATE INDEX idx_tags ON users USING GIN(tags);
```

**GiST Index (for geometric, full-text)**
```sql
-- For full-text search
CREATE INDEX idx_search ON articles USING GiST(to_tsvector('english', content));
```

**BRIN Index (for very large tables)**
```sql
-- Block Range Index - efficient for sorted data
CREATE INDEX idx_created ON logs USING BRIN(created_at);
```

**Hash Index**
```sql
CREATE INDEX idx_hash_email ON users USING HASH(email);
```

### Joins

**INNER JOIN**
```sql
SELECT u.username, o.order_date
FROM users u
INNER JOIN orders o ON u.id = o.user_id;
```

**LEFT JOIN (LEFT OUTER JOIN)**
```sql
SELECT u.username, o.order_date
FROM users u
LEFT JOIN orders o ON u.id = o.user_id;
```

**RIGHT JOIN (RIGHT OUTER JOIN)**
```sql
SELECT u.username, o.order_date
FROM users u
RIGHT JOIN orders o ON u.id = o.user_id;
```

**FULL OUTER JOIN**
```sql
SELECT u.username, o.order_date
FROM users u
FULL OUTER JOIN orders o ON u.id = o.user_id;
```

**CROSS JOIN**
```sql
SELECT * FROM colors CROSS JOIN sizes;
```

**LATERAL JOIN**
```sql
-- For each user, get their 3 most recent orders
SELECT u.username, o.*
FROM users u
CROSS JOIN LATERAL (
    SELECT * FROM orders WHERE user_id = u.id
    ORDER BY created_at DESC LIMIT 3
) o;
```

### Aggregate Functions

**Basic Aggregates**
```sql
SELECT COUNT(*) FROM users;
SELECT COUNT(DISTINCT email) FROM users;
SELECT SUM(price) FROM orders;
SELECT AVG(price) FROM products;
SELECT MIN(price), MAX(price) FROM products;
```

**GROUP BY**
```sql
SELECT user_id, COUNT(*) as order_count
FROM orders
GROUP BY user_id;

-- Multiple columns
SELECT category, status, COUNT(*)
FROM products
GROUP BY category, status;
```

**HAVING**
```sql
SELECT user_id, COUNT(*) as order_count
FROM orders
GROUP BY user_id
HAVING COUNT(*) > 5;
```

**FILTER Clause**
```sql
SELECT
    category,
    COUNT(*) FILTER (WHERE status = 'active') as active_count,
    COUNT(*) FILTER (WHERE status = 'inactive') as inactive_count
FROM products
GROUP BY category;
```

**Statistical Aggregates**
```sql
-- Standard deviation
SELECT STDDEV(price) FROM products;

-- Variance
SELECT VARIANCE(price) FROM products;

-- Correlation
SELECT CORR(price, sales) FROM products;
```

**Array Aggregation**
```sql
-- Collect values into array
SELECT user_id, ARRAY_AGG(product_id) as products
FROM orders
GROUP BY user_id;

-- String aggregation
SELECT user_id, STRING_AGG(product_name, ', ') as products
FROM orders
GROUP BY user_id;
```

### Subqueries

**Scalar Subquery**
```sql
SELECT * FROM products
WHERE price > (SELECT AVG(price) FROM products);
```

**IN Subquery**
```sql
SELECT * FROM users
WHERE id IN (SELECT user_id FROM orders WHERE total > 100);
```

**EXISTS Subquery**
```sql
SELECT * FROM users u
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);
```

**ANY/ALL**
```sql
SELECT * FROM products
WHERE price > ALL (SELECT price FROM products WHERE category = 'basic');

SELECT * FROM products
WHERE price > ANY (SELECT price FROM products WHERE category = 'basic');
```

### String Functions and Operators

**Concatenation**
```sql
SELECT first_name || ' ' || last_name as full_name FROM users;
SELECT CONCAT(first_name, ' ', last_name) FROM users;
```

**String Functions**
```sql
-- Length
SELECT LENGTH('hello');

-- Substring
SELECT SUBSTRING('hello world' FROM 1 FOR 5);

-- Position
SELECT POSITION('world' IN 'hello world');

-- Replace
SELECT REPLACE('hello world', 'world', 'postgres');

-- Case conversion
SELECT UPPER(name), LOWER(name) FROM users;

-- Trim
SELECT TRIM(BOTH ' ' FROM '  hello  ');

-- Split
SELECT STRING_TO_ARRAY('a,b,c', ',');

-- Pattern matching
SELECT * FROM users WHERE email LIKE '%@gmail.com';
SELECT * FROM users WHERE email SIMILAR TO '%@(gmail|yahoo)\.com';
```

**Regular Expressions**
```sql
-- Match
SELECT * FROM users WHERE email ~ '^[a-z]+@gmail\.com$';

-- Case-insensitive match
SELECT * FROM users WHERE email ~* '^admin';

-- Extract
SELECT SUBSTRING(email FROM '@(.*)$') as domain FROM users;

-- Replace with regex
SELECT REGEXP_REPLACE(phone, '[^0-9]', '', 'g');
```

### Date and Time Functions

**Current Date/Time**
```sql
SELECT NOW();                    -- Current timestamp with timezone
SELECT CURRENT_DATE;             -- Current date
SELECT CURRENT_TIME;             -- Current time
SELECT CURRENT_TIMESTAMP;        -- Current timestamp
SELECT CLOCK_TIMESTAMP();        -- Real-time clock (changes during query)
```

**Arithmetic**
```sql
-- Add interval
SELECT NOW() + INTERVAL '7 days';
SELECT NOW() + INTERVAL '1 year 2 months 3 days';

-- Subtract interval
SELECT NOW() - INTERVAL '1 hour';

-- Difference
SELECT AGE(NOW(), created_at) FROM users;
SELECT NOW() - created_at FROM users;
```

**Extraction**
```sql
SELECT EXTRACT(YEAR FROM NOW());
SELECT EXTRACT(MONTH FROM NOW());
SELECT EXTRACT(DAY FROM NOW());
SELECT DATE_PART('hour', NOW());
```

**Formatting**
```sql
SELECT TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS');
SELECT TO_CHAR(created_at, 'Day, DD Month YYYY') FROM users;

-- Parse string to date
SELECT TO_DATE('2024-01-15', 'YYYY-MM-DD');
SELECT TO_TIMESTAMP('2024-01-15 14:30:00', 'YYYY-MM-DD HH24:MI:SS');
```

**Truncation**
```sql
SELECT DATE_TRUNC('day', NOW());
SELECT DATE_TRUNC('hour', NOW());
SELECT DATE_TRUNC('month', NOW());
```

---

## Advanced Features

### Transactions

**Basic Transaction**
```sql
BEGIN;
-- or START TRANSACTION;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;

COMMIT;
-- or ROLLBACK to undo
```

**Isolation Levels**
```sql
-- Read Committed (default)
BEGIN ISOLATION LEVEL READ COMMITTED;

-- Repeatable Read
BEGIN ISOLATION LEVEL REPEATABLE READ;

-- Serializable
BEGIN ISOLATION LEVEL SERIALIZABLE;

-- Read Uncommitted (treated as Read Committed in Postgres)
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
```

**Savepoints**
```sql
BEGIN;
UPDATE users SET status = 'inactive' WHERE id = 1;
SAVEPOINT sp1;
UPDATE users SET status = 'deleted' WHERE id = 2;
ROLLBACK TO SAVEPOINT sp1;
COMMIT;
```

**Explicit Locking**
```sql
-- Row-level locks
SELECT * FROM users WHERE id = 1 FOR UPDATE;
SELECT * FROM users WHERE id = 1 FOR SHARE;

-- Table-level locks
LOCK TABLE users IN EXCLUSIVE MODE;
LOCK TABLE users IN SHARE MODE;
```

### Functions (Stored Procedures)

**Basic Function**
```sql
CREATE OR REPLACE FUNCTION get_user_count()
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM users);
END;
$$ LANGUAGE plpgsql;

-- Call function
SELECT get_user_count();
```

**Function with Parameters**
```sql
CREATE OR REPLACE FUNCTION get_user_orders(user_id_param INT)
RETURNS TABLE(order_id INT, total NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT id, order_total FROM orders WHERE user_id = user_id_param;
END;
$$ LANGUAGE plpgsql;

-- Call function
SELECT * FROM get_user_orders(1);
```

**Function with OUT Parameters**
```sql
CREATE OR REPLACE FUNCTION get_stats(
    OUT total_users INT,
    OUT total_orders INT
) AS $$
BEGIN
    SELECT COUNT(*) INTO total_users FROM users;
    SELECT COUNT(*) INTO total_orders FROM orders;
END;
$$ LANGUAGE plpgsql;

-- Call function
SELECT * FROM get_stats();
```

**Conditional Logic**
```sql
CREATE OR REPLACE FUNCTION calculate_discount(price NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    IF price > 100 THEN
        RETURN price * 0.9;  -- 10% discount
    ELSIF price > 50 THEN
        RETURN price * 0.95; -- 5% discount
    ELSE
        RETURN price;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

**Loops**
```sql
CREATE OR REPLACE FUNCTION sum_to_n(n INT)
RETURNS INT AS $$
DECLARE
    i INT := 1;
    total INT := 0;
BEGIN
    WHILE i <= n LOOP
        total := total + i;
        i := i + 1;
    END LOOP;
    RETURN total;
END;
$$ LANGUAGE plpgsql;
```

**Exception Handling**
```sql
CREATE OR REPLACE FUNCTION safe_divide(a NUMERIC, b NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN a / b;
EXCEPTION
    WHEN division_by_zero THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error occurred: %', SQLERRM;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

### Procedures (PostgreSQL 11+)

**Creating Procedures**
```sql
CREATE OR REPLACE PROCEDURE update_user_status(
    user_id_param INT,
    new_status VARCHAR
) AS $$
BEGIN
    UPDATE users SET status = new_status WHERE id = user_id_param;
    COMMIT;
END;
$$ LANGUAGE plpgsql;

-- Call procedure
CALL update_user_status(1, 'active');
```

**Procedures with Transactions**
```sql
CREATE OR REPLACE PROCEDURE transfer_funds(
    from_account INT,
    to_account INT,
    amount NUMERIC
) AS $$
BEGIN
    UPDATE accounts SET balance = balance - amount WHERE id = from_account;
    UPDATE accounts SET balance = balance + amount WHERE id = to_account;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
$$ LANGUAGE plpgsql;
```

### Triggers

**BEFORE INSERT Trigger**
```sql
CREATE OR REPLACE FUNCTION set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    NEW.username := LOWER(NEW.username);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_user_insert
BEFORE INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION set_timestamp();
```

**AFTER UPDATE Trigger**
```sql
CREATE OR REPLACE FUNCTION log_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status != OLD.status THEN
        INSERT INTO status_history (user_id, old_status, new_status, changed_at)
        VALUES (NEW.id, OLD.status, NEW.status, NOW());
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_user_update
AFTER UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION log_status_change();
```

**INSTEAD OF Trigger (for Views)**
```sql
CREATE OR REPLACE FUNCTION user_view_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO users (username, email)
    VALUES (NEW.username, NEW.email);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER instead_of_insert
INSTEAD OF INSERT ON user_view
FOR EACH ROW
EXECUTE FUNCTION user_view_insert();
```

**Statement-Level Trigger**
```sql
CREATE OR REPLACE FUNCTION audit_operation()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (table_name, operation, timestamp)
    VALUES (TG_TABLE_NAME, TG_OP, NOW());
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_users
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH STATEMENT
EXECUTE FUNCTION audit_operation();
```

### Views

**Creating Views**
```sql
CREATE VIEW user_order_summary AS
SELECT
    u.id,
    u.username,
    COUNT(o.id) as order_count,
    COALESCE(SUM(o.total), 0) as total_spent
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.username;

-- Query view
SELECT * FROM user_order_summary WHERE order_count > 5;
```

**Updatable Views**
```sql
CREATE VIEW active_users AS
SELECT * FROM users WHERE status = 'active';

-- Can update through view
UPDATE active_users SET email = 'new@example.com' WHERE id = 1;
```

**Materialized Views**
```sql
-- Create materialized view
CREATE MATERIALIZED VIEW user_stats AS
SELECT
    user_id,
    COUNT(*) as order_count,
    SUM(total) as total_spent
FROM orders
GROUP BY user_id;

-- Create index on materialized view
CREATE INDEX idx_user_stats ON user_stats(user_id);

-- Refresh materialized view
REFRESH MATERIALIZED VIEW user_stats;

-- Refresh concurrently (requires unique index)
CREATE UNIQUE INDEX idx_user_stats_unique ON user_stats(user_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY user_stats;
```

### Partitioning

**Range Partitioning**
```sql
-- Parent table
CREATE TABLE orders (
    id SERIAL,
    order_date DATE NOT NULL,
    total NUMERIC
) PARTITION BY RANGE (order_date);

-- Child partitions
CREATE TABLE orders_2023 PARTITION OF orders
FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE orders_2024 PARTITION OF orders
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- Default partition
CREATE TABLE orders_default PARTITION OF orders DEFAULT;
```

**List Partitioning**
```sql
CREATE TABLE users (
    id SERIAL,
    country VARCHAR(2) NOT NULL,
    username VARCHAR(50)
) PARTITION BY LIST (country);

CREATE TABLE users_us PARTITION OF users
FOR VALUES IN ('US');

CREATE TABLE users_eu PARTITION OF users
FOR VALUES IN ('UK', 'FR', 'DE');
```

**Hash Partitioning**
```sql
CREATE TABLE logs (
    id SERIAL,
    message TEXT,
    created_at TIMESTAMPTZ
) PARTITION BY HASH (id);

CREATE TABLE logs_0 PARTITION OF logs
FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE logs_1 PARTITION OF logs
FOR VALUES WITH (MODULUS 4, REMAINDER 1);
```

**Sub-Partitioning**
```sql
-- Partition by range, then by list
CREATE TABLE sales (
    id SERIAL,
    sale_date DATE,
    region VARCHAR(2)
) PARTITION BY RANGE (sale_date);

CREATE TABLE sales_2024 PARTITION OF sales
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01')
PARTITION BY LIST (region);

CREATE TABLE sales_2024_us PARTITION OF sales_2024
FOR VALUES IN ('US');
```

### Replication

**Streaming Replication (Physical)**

Primary Configuration (postgresql.conf):
```conf
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
```

Primary Setup:
```sql
-- Create replication user
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'password';

-- In pg_hba.conf, add:
-- host replication replicator standby_ip/32 md5
```

Standby Setup:
```bash
# Base backup from primary
pg_basebackup -h primary_ip -D /var/lib/postgresql/data -U replicator -P -v -R

# standby.signal file created by -R flag
# postgresql.auto.conf contains primary connection info
```

**Logical Replication**

Publisher:
```sql
-- Set wal_level = logical in postgresql.conf

-- Create publication
CREATE PUBLICATION my_publication FOR TABLE users, orders;

-- Or publish all tables
CREATE PUBLICATION all_tables FOR ALL TABLES;
```

Subscriber:
```sql
-- Create subscription
CREATE SUBSCRIPTION my_subscription
CONNECTION 'host=publisher_ip dbname=mydb user=replicator password=pass'
PUBLICATION my_publication;

-- Monitor replication
SELECT * FROM pg_stat_subscription;
```

### Full-Text Search

**Basic Full-Text Search**
```sql
-- Create tsvector column
ALTER TABLE articles ADD COLUMN tsv tsvector;

-- Update tsvector
UPDATE articles SET tsv =
    to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(content, ''));

-- Create GIN index
CREATE INDEX idx_tsv ON articles USING GIN(tsv);

-- Search
SELECT * FROM articles
WHERE tsv @@ to_tsquery('english', 'postgresql & database');
```

**Automatic tsvector Updates**
```sql
-- Trigger-based
CREATE TRIGGER tsvector_update BEFORE INSERT OR UPDATE ON articles
FOR EACH ROW EXECUTE FUNCTION
tsvector_update_trigger(tsv, 'pg_catalog.english', title, content);

-- Or generated column (PostgreSQL 12+)
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title TEXT,
    content TEXT,
    tsv tsvector GENERATED ALWAYS AS (
        to_tsvector('english', COALESCE(title, '') || ' ' || COALESCE(content, ''))
    ) STORED
);
```

**Ranking Results**
```sql
SELECT
    title,
    ts_rank(tsv, query) as rank
FROM articles, to_tsquery('english', 'postgresql') query
WHERE tsv @@ query
ORDER BY rank DESC;
```

**Phrase Search**
```sql
-- Exact phrase
SELECT * FROM articles
WHERE tsv @@ phraseto_tsquery('english', 'database management system');
```

**Highlighting Results**
```sql
SELECT
    title,
    ts_headline('english', content, to_tsquery('postgresql'),
        'MaxWords=50, MinWords=20') as snippet
FROM articles
WHERE tsv @@ to_tsquery('postgresql');
```

### JSON and JSONB

**Storing JSON**
```sql
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    data JSONB
);

INSERT INTO events (data) VALUES
('{"user": "john", "action": "login", "timestamp": "2024-01-15"}'),
('{"user": "jane", "action": "logout", "ip": "192.168.1.1"}');
```

**Querying JSONB**
```sql
-- Extract value (returns JSON)
SELECT data->'user' FROM events;

-- Extract text value
SELECT data->>'user' FROM events;

-- Nested access
SELECT data->'metadata'->'ip' FROM events;

-- Path extraction
SELECT data#>'{metadata,ip}' FROM events;
SELECT data#>>'{metadata,ip}' as ip FROM events;
```

**JSONB Operators**
```sql
-- Contains
SELECT * FROM events WHERE data @> '{"action": "login"}';

-- Exists key
SELECT * FROM events WHERE data ? 'ip';

-- Exists any key
SELECT * FROM events WHERE data ?| ARRAY['ip', 'user'];

-- Exists all keys
SELECT * FROM events WHERE data ?& ARRAY['user', 'action'];
```

**JSONB Functions**
```sql
-- Build JSON
SELECT jsonb_build_object('name', username, 'email', email) FROM users;

-- Build array
SELECT jsonb_build_array(1, 2, 3, 'hello');

-- Array aggregation
SELECT jsonb_agg(username) FROM users;

-- Object aggregation
SELECT jsonb_object_agg(id, username) FROM users;

-- Set value
UPDATE events SET data = jsonb_set(data, '{timestamp}', '"2024-01-16"');

-- Remove key
UPDATE events SET data = data - 'ip';

-- Concatenate
UPDATE events SET data = data || '{"new_field": "value"}';
```

**JSONB Indexing**
```sql
-- GIN index for containment queries
CREATE INDEX idx_data ON events USING GIN(data);

-- Expression index
CREATE INDEX idx_user ON events USING GIN((data->'user'));

-- Path index
CREATE INDEX idx_action ON events ((data->>'action'));
```

### Window Functions

**ROW_NUMBER, RANK, DENSE_RANK**
```sql
SELECT
    username,
    score,
    ROW_NUMBER() OVER (ORDER BY score DESC) as row_num,
    RANK() OVER (ORDER BY score DESC) as rank,
    DENSE_RANK() OVER (ORDER BY score DESC) as dense_rank
FROM user_scores;
```

**Partitioned Window Functions**
```sql
SELECT
    category,
    product_name,
    price,
    AVG(price) OVER (PARTITION BY category) as avg_category_price,
    price - AVG(price) OVER (PARTITION BY category) as price_diff
FROM products;
```

**LAG and LEAD**
```sql
SELECT
    date,
    revenue,
    LAG(revenue, 1) OVER (ORDER BY date) as previous_day,
    LEAD(revenue, 1) OVER (ORDER BY date) as next_day,
    revenue - LAG(revenue, 1) OVER (ORDER BY date) as daily_change
FROM daily_sales;
```

**FIRST_VALUE and LAST_VALUE**
```sql
SELECT
    date,
    revenue,
    FIRST_VALUE(revenue) OVER (ORDER BY date) as first_revenue,
    LAST_VALUE(revenue) OVER (
        ORDER BY date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as last_revenue
FROM daily_sales;
```

**NTH_VALUE**
```sql
SELECT
    product_name,
    price,
    NTH_VALUE(price, 2) OVER (ORDER BY price DESC) as second_highest_price
FROM products;
```

**NTILE**
```sql
-- Divide into quartiles
SELECT
    username,
    score,
    NTILE(4) OVER (ORDER BY score DESC) as quartile
FROM user_scores;
```

**Frame Clauses**
```sql
-- Running total
SELECT
    date,
    amount,
    SUM(amount) OVER (ORDER BY date ROWS UNBOUNDED PRECEDING) as running_total
FROM transactions;

-- Moving average (7-day)
SELECT
    date,
    value,
    AVG(value) OVER (
        ORDER BY date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7day
FROM metrics;
```

### Common Table Expressions (CTE)

**Basic CTE**
```sql
WITH recent_orders AS (
    SELECT * FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT user_id, COUNT(*) as order_count
FROM recent_orders
GROUP BY user_id;
```

**Multiple CTEs**
```sql
WITH
    active_users AS (
        SELECT * FROM users WHERE status = 'active'
    ),
    user_stats AS (
        SELECT user_id, COUNT(*) as order_count
        FROM orders
        GROUP BY user_id
    )
SELECT u.username, COALESCE(s.order_count, 0)
FROM active_users u
LEFT JOIN user_stats s ON u.id = s.user_id;
```

**Recursive CTE**
```sql
-- Employee hierarchy
WITH RECURSIVE employee_tree AS (
    -- Base case
    SELECT id, name, manager_id, 1 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case
    SELECT e.id, e.name, e.manager_id, et.level + 1
    FROM employees e
    JOIN employee_tree et ON e.manager_id = et.id
)
SELECT * FROM employee_tree ORDER BY level, name;
```

**Recursive CTE - Graph Traversal**
```sql
-- Find all paths in a graph
WITH RECURSIVE paths AS (
    SELECT
        id,
        ARRAY[id] as path,
        0 as depth
    FROM nodes
    WHERE id = 1

    UNION ALL

    SELECT
        e.to_node,
        p.path || e.to_node,
        p.depth + 1
    FROM paths p
    JOIN edges e ON e.from_node = p.id
    WHERE NOT e.to_node = ANY(p.path)  -- Prevent cycles
    AND p.depth < 10  -- Limit depth
)
SELECT * FROM paths;
```

**Writable CTE**
```sql
WITH deleted_orders AS (
    DELETE FROM orders
    WHERE created_at < NOW() - INTERVAL '1 year'
    RETURNING *
)
INSERT INTO archived_orders
SELECT * FROM deleted_orders;
```

### Array Operations

**Array Functions**
```sql
-- Create array
SELECT ARRAY[1, 2, 3, 4, 5];
SELECT ARRAY(SELECT id FROM users LIMIT 5);

-- Array length
SELECT array_length(ARRAY[1,2,3], 1);

-- Array append
SELECT array_append(ARRAY[1,2,3], 4);

-- Array prepend
SELECT array_prepend(0, ARRAY[1,2,3]);

-- Array concatenation
SELECT ARRAY[1,2] || ARRAY[3,4];

-- Array contains
SELECT ARRAY[1,2,3] @> ARRAY[2];

-- Array overlap
SELECT ARRAY[1,2,3] && ARRAY[3,4,5];

-- Unnest array
SELECT unnest(ARRAY[1,2,3]);
```

**Array Aggregation**
```sql
SELECT
    user_id,
    array_agg(product_id) as products,
    array_agg(product_id ORDER BY created_at DESC) as recent_products
FROM orders
GROUP BY user_id;
```

### User Management and Security

**Creating Users**
```sql
CREATE USER username WITH PASSWORD 'password';
CREATE ROLE appuser WITH LOGIN PASSWORD 'password';
```

**Granting Privileges**
```sql
-- Database privileges
GRANT CONNECT ON DATABASE mydb TO username;
GRANT ALL PRIVILEGES ON DATABASE mydb TO username;

-- Schema privileges
GRANT USAGE ON SCHEMA public TO username;
GRANT CREATE ON SCHEMA public TO username;

-- Table privileges
GRANT SELECT ON users TO username;
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO username;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO username;

-- Sequence privileges (for SERIAL columns)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO username;

-- Function privileges
GRANT EXECUTE ON FUNCTION my_function TO username;

-- Default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO username;
```

**Revoking Privileges**
```sql
REVOKE INSERT ON users FROM username;
REVOKE ALL PRIVILEGES ON DATABASE mydb FROM username;
```

**Roles**
```sql
-- Create role
CREATE ROLE readonly;

-- Grant privileges to role
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

-- Grant role to user
GRANT readonly TO username;

-- Set role
SET ROLE readonly;
RESET ROLE;
```

**Row-Level Security (RLS)**
```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY user_isolation ON users
FOR ALL
TO appuser
USING (user_id = current_user_id());

-- Force RLS even for table owner
ALTER TABLE users FORCE ROW LEVEL SECURITY;
```

### Extensions

**Installing Extensions**
```sql
-- List available extensions
SELECT * FROM pg_available_extensions;

-- Install extension
CREATE EXTENSION IF NOT EXISTS pg_trgm;     -- Trigram matching
CREATE EXTENSION IF NOT EXISTS pgcrypto;    -- Cryptographic functions
CREATE EXTENSION IF NOT EXISTS uuid-ossp;   -- UUID generation
CREATE EXTENSION IF NOT EXISTS hstore;      -- Key-value storage
CREATE EXTENSION IF NOT EXISTS postgis;     -- Geographic objects
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;  -- Query stats
CREATE EXTENSION IF NOT EXISTS btree_gist;  -- Additional index types
```

**Using Extensions**
```sql
-- UUID generation
SELECT uuid_generate_v4();

-- Trigram similarity
SELECT similarity('hello', 'hallo');
SELECT * FROM products WHERE name % 'prodct';  -- Fuzzy match

-- Encryption
SELECT crypt('password', gen_salt('bf'));
SELECT digest('text', 'sha256');

-- hstore
SELECT 'a=>1, b=>2'::hstore;
SELECT hstore_to_json('a=>1, b=>2'::hstore);
```

### Performance Optimization

**EXPLAIN and ANALYZE**
```sql
-- Show query plan
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';

-- Show actual execution
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

-- Detailed analysis
EXPLAIN (ANALYZE, BUFFERS, VERBOSE) SELECT * FROM users;
```

**Vacuum and Analyze**
```sql
-- Update statistics
ANALYZE users;
ANALYZE;  -- All tables

-- Reclaim space and update statistics
VACUUM ANALYZE users;

-- Full vacuum (locks table)
VACUUM FULL users;

-- Auto-vacuum settings (postgresql.conf)
autovacuum = on
autovacuum_vacuum_scale_factor = 0.2
autovacuum_analyze_scale_factor = 0.1
```

**Index Optimization**
```sql
-- Find unused indexes
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY schemaname, tablename;

-- Find duplicate indexes
SELECT pg_size_pretty(SUM(pg_relation_size(idx))::BIGINT) AS size,
       (array_agg(idx))[1] AS idx1, (array_agg(idx))[2] AS idx2,
       (array_agg(idx))[3] AS idx3, (array_agg(idx))[4] AS idx4
FROM (
    SELECT indexrelid::regclass AS idx, indrelid::regclass AS tbl,
           (indrelid::text ||E'\n'|| indclass::text ||E'\n'||
            indkey::text ||E'\n'||COALESCE(indexprs::text,'')||E'\n'||
            COALESCE(indpred::text,'')) AS key
    FROM pg_index
) sub
GROUP BY key, tbl
HAVING COUNT(*) > 1;

-- Rebuild index
REINDEX INDEX idx_name;
REINDEX TABLE users;
```

**Query Optimization Tips**
```sql
-- Use DISTINCT ON instead of subqueries
SELECT DISTINCT ON (user_id) *
FROM orders
ORDER BY user_id, created_at DESC;

-- Use EXISTS instead of IN for large sets
SELECT * FROM users
WHERE EXISTS (SELECT 1 FROM orders WHERE user_id = users.id);

-- Avoid SELECT *
SELECT id, username, email FROM users;

-- Use covering indexes
CREATE INDEX idx_users_covering ON users(email) INCLUDE (username, created_at);

-- Partial indexes for filtered queries
CREATE INDEX idx_active_users ON users(username) WHERE status = 'active';
```

**Connection Pooling**
```sql
-- Use connection pooler like pgBouncer
-- postgresql.conf settings
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
work_mem = 4MB
```

### Backup and Restore

**pg_dump (Logical Backup)**
```bash
# Backup single database
pg_dump -U postgres -d mydb -F c -f mydb.backup

# Backup with plain SQL
pg_dump -U postgres mydb > mydb.sql

# Backup specific tables
pg_dump -U postgres -t users -t orders mydb > tables.sql

# Backup all databases
pg_dumpall -U postgres > all_databases.sql

# Backup only schema
pg_dump -U postgres -s mydb > schema.sql

# Backup only data
pg_dump -U postgres -a mydb > data.sql
```

**Restore**
```bash
# Restore custom format
pg_restore -U postgres -d mydb mydb.backup

# Restore SQL format
psql -U postgres -d mydb < mydb.sql

# Restore with parallelism
pg_restore -U postgres -d mydb -j 4 mydb.backup
```

**Physical Backup (pg_basebackup)**
```bash
# Base backup
pg_basebackup -D /backup/path -F tar -z -P -U postgres

# For point-in-time recovery
pg_basebackup -D /backup/path -X stream -P -U postgres
```

**Point-in-Time Recovery (PITR)**
```conf
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /archive/%f'

# Restore to specific time
restore_command = 'cp /archive/%f %p'
recovery_target_time = '2024-01-15 14:30:00'
```

### Monitoring and Troubleshooting

**System Information**
```sql
-- Database size
SELECT pg_size_pretty(pg_database_size('mydb'));

-- Table sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Index sizes
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_indexes
JOIN pg_stat_user_indexes USING (schemaname, tablename, indexname)
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;
```

**Activity Monitoring**
```sql
-- Current connections
SELECT * FROM pg_stat_activity;

-- Long-running queries
SELECT
    pid,
    now() - query_start AS duration,
    query,
    state
FROM pg_stat_activity
WHERE state != 'idle'
AND now() - query_start > interval '5 minutes'
ORDER BY duration DESC;

-- Kill query
SELECT pg_cancel_backend(pid);

-- Kill connection
SELECT pg_terminate_backend(pid);

-- Locks
SELECT * FROM pg_locks;

-- Blocking queries
SELECT
    blocked_locks.pid AS blocked_pid,
    blocked_activity.query AS blocked_query,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.query AS blocking_query
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

**Table Statistics**
```sql
-- Table access patterns
SELECT * FROM pg_stat_user_tables;

-- Index usage
SELECT * FROM pg_stat_user_indexes;

-- Cache hit ratio
SELECT
    sum(heap_blks_read) as heap_read,
    sum(heap_blks_hit) as heap_hit,
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as cache_ratio
FROM pg_statio_user_tables;
```

**Query Statistics (pg_stat_statements)**
```sql
-- Enable extension
CREATE EXTENSION pg_stat_statements;

-- Top queries by total time
SELECT
    calls,
    total_exec_time,
    mean_exec_time,
    query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- Reset statistics
SELECT pg_stat_statements_reset();
```

### Configuration

**postgresql.conf Key Settings**
```conf
# Connection Settings
max_connections = 100
superuser_reserved_connections = 3

# Memory Settings
shared_buffers = 256MB              # 25% of RAM
effective_cache_size = 1GB          # 50-75% of RAM
work_mem = 4MB                      # Per operation
maintenance_work_mem = 64MB         # For maintenance operations

# WAL Settings
wal_level = replica
wal_buffers = 16MB
checkpoint_completion_target = 0.9
max_wal_size = 1GB
min_wal_size = 80MB

# Query Planner
random_page_cost = 1.1              # Lower for SSD
effective_io_concurrency = 200      # Higher for SSD

# Logging
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d.log'
log_statement = 'ddl'
log_duration = off
log_min_duration_statement = 1000   # Log queries > 1 second

# Autovacuum
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 1min
```

**pg_hba.conf (Authentication)**
```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local connections
local   all             all                                     peer

# IPv4 local connections
host    all             all             127.0.0.1/32            scram-sha-256

# IPv6 local connections
host    all             all             ::1/128                 scram-sha-256

# Remote connections
host    all             all             0.0.0.0/0               scram-sha-256
```

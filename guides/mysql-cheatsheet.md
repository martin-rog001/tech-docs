# MySQL Cheatsheet

## Essential Features

### Data Types

**String Types**
- `CHAR(n)` - Fixed-length string (0-255 characters)
- `VARCHAR(n)` - Variable-length string (0-65,535 characters)
- `TEXT` - Large text data (up to 65,535 characters)
- `MEDIUMTEXT` - Medium text data (up to 16,777,215 characters)
- `LONGTEXT` - Very large text data (up to 4GB)

**Numeric Types**
- `INT` - Integer (-2,147,483,648 to 2,147,483,647)
- `BIGINT` - Large integer (-9,223,372,036,854,775,808 to 9,223,372,036,854,775,807)
- `DECIMAL(p,s)` - Exact numeric value with precision
- `FLOAT` - Floating point number (approximate)
- `DOUBLE` - Double precision floating point

**Date and Time Types**
- `DATE` - Date value (YYYY-MM-DD)
- `DATETIME` - Date and time (YYYY-MM-DD HH:MM:SS)
- `TIMESTAMP` - Unix timestamp (auto-updates on row change)
- `TIME` - Time value (HH:MM:SS)
- `YEAR` - Year value (1901-2155)

**Other Types**
- `BOOLEAN` - True/False (stored as TINYINT 0 or 1)
- `ENUM` - String with predefined values
- `JSON` - JSON formatted data
- `BLOB` - Binary large object

### Basic CRUD Operations

**CREATE**
```sql
-- Create database
CREATE DATABASE myapp;

-- Create table
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

-- With LIMIT
SELECT * FROM users LIMIT 10;
```

**UPDATE**
```sql
-- Update single row
UPDATE users SET email = 'newemail@example.com' WHERE id = 1;

-- Update multiple rows
UPDATE users SET created_at = NOW() WHERE created_at IS NULL;
```

**DELETE**
```sql
-- Delete specific rows
DELETE FROM users WHERE id = 1;

-- Delete all rows (careful!)
DELETE FROM users;

-- Truncate (faster, resets auto_increment)
TRUNCATE TABLE users;
```

### Constraints

**PRIMARY KEY**
- Uniquely identifies each row in a table
```sql
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT
);
```

**FOREIGN KEY**
- Links two tables together
```sql
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**UNIQUE**
- Ensures all values in a column are unique
```sql
CREATE TABLE users (
    email VARCHAR(100) UNIQUE
);
```

**NOT NULL**
- Prevents NULL values in a column
```sql
CREATE TABLE users (
    username VARCHAR(50) NOT NULL
);
```

**CHECK**
- Ensures values meet a specific condition
```sql
CREATE TABLE products (
    price DECIMAL(10,2) CHECK (price > 0)
);
```

**DEFAULT**
- Sets a default value for a column
```sql
CREATE TABLE users (
    status VARCHAR(20) DEFAULT 'active'
);
```

### Indexes

**Basic Index**
- Speeds up SELECT queries
```sql
CREATE INDEX idx_username ON users(username);
```

**Unique Index**
- Ensures uniqueness and speeds up queries
```sql
CREATE UNIQUE INDEX idx_email ON users(email);
```

**Composite Index**
- Index on multiple columns
```sql
CREATE INDEX idx_name ON users(first_name, last_name);
```

**Full-Text Index**
- For text searching
```sql
CREATE FULLTEXT INDEX idx_content ON articles(title, body);
SELECT * FROM articles WHERE MATCH(title, body) AGAINST('search term');
```

### Joins

**INNER JOIN**
- Returns matching rows from both tables
```sql
SELECT users.username, orders.order_date
FROM users
INNER JOIN orders ON users.id = orders.user_id;
```

**LEFT JOIN**
- Returns all rows from left table, matching rows from right
```sql
SELECT users.username, orders.order_date
FROM users
LEFT JOIN orders ON users.id = orders.user_id;
```

**RIGHT JOIN**
- Returns all rows from right table, matching rows from left
```sql
SELECT users.username, orders.order_date
FROM users
RIGHT JOIN orders ON users.id = orders.user_id;
```

**CROSS JOIN**
- Cartesian product of both tables
```sql
SELECT * FROM colors CROSS JOIN sizes;
```

### Aggregate Functions

**COUNT**
- Counts number of rows
```sql
SELECT COUNT(*) FROM users;
SELECT COUNT(DISTINCT email) FROM users;
```

**SUM**
- Calculates sum of numeric column
```sql
SELECT SUM(price) FROM orders;
```

**AVG**
- Calculates average value
```sql
SELECT AVG(price) FROM products;
```

**MIN/MAX**
- Finds minimum/maximum value
```sql
SELECT MIN(price), MAX(price) FROM products;
```

**GROUP BY**
- Groups rows by column values
```sql
SELECT user_id, COUNT(*) as order_count
FROM orders
GROUP BY user_id;
```

**HAVING**
- Filters grouped results
```sql
SELECT user_id, COUNT(*) as order_count
FROM orders
GROUP BY user_id
HAVING order_count > 5;
```

### Subqueries

**Scalar Subquery**
- Returns single value
```sql
SELECT * FROM products
WHERE price > (SELECT AVG(price) FROM products);
```

**IN Subquery**
- Tests if value exists in subquery results
```sql
SELECT * FROM users
WHERE id IN (SELECT user_id FROM orders WHERE total > 100);
```

**EXISTS Subquery**
- Tests if subquery returns any rows
```sql
SELECT * FROM users
WHERE EXISTS (SELECT 1 FROM orders WHERE orders.user_id = users.id);
```

### String Functions

- `CONCAT()` - Concatenates strings
- `SUBSTRING()` - Extracts substring
- `LENGTH()` - Returns string length
- `UPPER()/LOWER()` - Changes case
- `TRIM()` - Removes whitespace
- `REPLACE()` - Replaces substring
- `LIKE` - Pattern matching with wildcards (%, _)

```sql
SELECT CONCAT(first_name, ' ', last_name) as full_name FROM users;
SELECT * FROM users WHERE email LIKE '%@gmail.com';
```

### Date Functions

- `NOW()` - Current date and time
- `CURDATE()` - Current date
- `CURTIME()` - Current time
- `DATE_ADD()` - Add interval to date
- `DATE_SUB()` - Subtract interval from date
- `DATEDIFF()` - Difference between dates
- `DATE_FORMAT()` - Format date

```sql
SELECT * FROM orders WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY);
SELECT DATE_FORMAT(created_at, '%Y-%m-%d') FROM users;
```

---

## Advanced Features

### Transactions

**ACID Properties**
- Atomicity: All or nothing
- Consistency: Valid state before and after
- Isolation: Transactions don't interfere
- Durability: Committed changes persist

**Basic Transaction**
```sql
START TRANSACTION;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;

COMMIT;
-- or ROLLBACK to undo
```

**Transaction Isolation Levels**
```sql
-- READ UNCOMMITTED (lowest isolation)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- READ COMMITTED
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- REPEATABLE READ (MySQL default)
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- SERIALIZABLE (highest isolation)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

**Savepoints**
```sql
START TRANSACTION;
UPDATE users SET status = 'inactive' WHERE id = 1;
SAVEPOINT sp1;
UPDATE users SET status = 'deleted' WHERE id = 2;
ROLLBACK TO SAVEPOINT sp1;
COMMIT;
```

### Stored Procedures

**Creating Procedures**
```sql
DELIMITER //
CREATE PROCEDURE GetUserOrders(IN userId INT)
BEGIN
    SELECT * FROM orders WHERE user_id = userId;
END //
DELIMITER ;

-- Call procedure
CALL GetUserOrders(1);
```

**Procedures with OUT Parameters**
```sql
DELIMITER //
CREATE PROCEDURE GetOrderCount(IN userId INT, OUT orderCount INT)
BEGIN
    SELECT COUNT(*) INTO orderCount FROM orders WHERE user_id = userId;
END //
DELIMITER ;

CALL GetOrderCount(1, @count);
SELECT @count;
```

**Conditional Logic**
```sql
DELIMITER //
CREATE PROCEDURE UpdateUserStatus(IN userId INT)
BEGIN
    DECLARE orderCount INT;
    SELECT COUNT(*) INTO orderCount FROM orders WHERE user_id = userId;

    IF orderCount > 10 THEN
        UPDATE users SET status = 'premium' WHERE id = userId;
    ELSE
        UPDATE users SET status = 'regular' WHERE id = userId;
    END IF;
END //
DELIMITER ;
```

### Functions

**Creating User-Defined Functions**
```sql
DELIMITER //
CREATE FUNCTION GetFullName(userId INT) RETURNS VARCHAR(200)
DETERMINISTIC
BEGIN
    DECLARE fullName VARCHAR(200);
    SELECT CONCAT(first_name, ' ', last_name) INTO fullName
    FROM users WHERE id = userId;
    RETURN fullName;
END //
DELIMITER ;

-- Use function
SELECT GetFullName(1);
```

### Triggers

**BEFORE INSERT Trigger**
```sql
DELIMITER //
CREATE TRIGGER before_user_insert
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    SET NEW.created_at = NOW();
    SET NEW.username = LOWER(NEW.username);
END //
DELIMITER ;
```

**AFTER UPDATE Trigger**
```sql
DELIMITER //
CREATE TRIGGER after_order_update
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.status != OLD.status THEN
        INSERT INTO order_history (order_id, old_status, new_status, changed_at)
        VALUES (NEW.id, OLD.status, NEW.status, NOW());
    END IF;
END //
DELIMITER ;
```

**BEFORE DELETE Trigger**
```sql
DELIMITER //
CREATE TRIGGER before_user_delete
BEFORE DELETE ON users
FOR EACH ROW
BEGIN
    INSERT INTO deleted_users SELECT * FROM users WHERE id = OLD.id;
END //
DELIMITER ;
```

### Views

**Creating Views**
```sql
CREATE VIEW user_order_summary AS
SELECT
    u.id,
    u.username,
    COUNT(o.id) as order_count,
    SUM(o.total) as total_spent
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

-- Can insert/update through view
UPDATE active_users SET email = 'new@example.com' WHERE id = 1;
```

**Materialized Views (Using Tables)**
```sql
-- MySQL doesn't have native materialized views, use tables
CREATE TABLE user_stats AS
SELECT user_id, COUNT(*) as order_count
FROM orders
GROUP BY user_id;

-- Refresh periodically
TRUNCATE TABLE user_stats;
INSERT INTO user_stats
SELECT user_id, COUNT(*) FROM orders GROUP BY user_id;
```

### Partitioning

**RANGE Partitioning**
```sql
CREATE TABLE orders (
    id INT,
    order_date DATE,
    total DECIMAL(10,2)
)
PARTITION BY RANGE (YEAR(order_date)) (
    PARTITION p2020 VALUES LESS THAN (2021),
    PARTITION p2021 VALUES LESS THAN (2022),
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

**LIST Partitioning**
```sql
CREATE TABLE users (
    id INT,
    country VARCHAR(2)
)
PARTITION BY LIST COLUMNS(country) (
    PARTITION p_north_america VALUES IN ('US', 'CA', 'MX'),
    PARTITION p_europe VALUES IN ('UK', 'FR', 'DE'),
    PARTITION p_asia VALUES IN ('JP', 'CN', 'IN')
);
```

**HASH Partitioning**
```sql
CREATE TABLE users (
    id INT,
    username VARCHAR(50)
)
PARTITION BY HASH(id)
PARTITIONS 4;
```

### Replication

**Master-Slave Replication**

Master Configuration:
```sql
-- Enable binary logging
-- In my.cnf:
[mysqld]
server-id = 1
log-bin = mysql-bin
binlog-do-db = myapp

-- Create replication user
CREATE USER 'replica'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';

-- Get master status
SHOW MASTER STATUS;
```

Slave Configuration:
```sql
-- In my.cnf:
[mysqld]
server-id = 2
relay-log = mysql-relay-bin

-- Configure slave
CHANGE MASTER TO
    MASTER_HOST='master_ip',
    MASTER_USER='replica',
    MASTER_PASSWORD='password',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=107;

START SLAVE;
SHOW SLAVE STATUS\G
```

### Performance Optimization

**Query Optimization**
```sql
-- Use EXPLAIN to analyze queries
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';

-- Use indexes appropriately
CREATE INDEX idx_email ON users(email);

-- Avoid SELECT *
SELECT id, username FROM users;

-- Use LIMIT for pagination
SELECT * FROM users LIMIT 10 OFFSET 20;
```

**Query Cache (MySQL 5.7 and earlier)**
```sql
-- Check query cache status
SHOW VARIABLES LIKE 'query_cache%';

-- Enable query cache in my.cnf
[mysqld]
query_cache_type = 1
query_cache_size = 64M
```

**Index Optimization**
```sql
-- Analyze index usage
SHOW INDEX FROM users;

-- Remove unused indexes
DROP INDEX unused_index ON users;

-- Rebuild indexes
OPTIMIZE TABLE users;
```

**Table Optimization**
```sql
-- Analyze table
ANALYZE TABLE users;

-- Optimize table (defragment, rebuild indexes)
OPTIMIZE TABLE users;

-- Check table integrity
CHECK TABLE users;

-- Repair corrupted table
REPAIR TABLE users;
```

### Storage Engines

**InnoDB (Default)**
- ACID compliant transactions
- Foreign key support
- Row-level locking
- Crash recovery
```sql
CREATE TABLE users (
    id INT PRIMARY KEY
) ENGINE=InnoDB;
```

**MyISAM**
- Fast for read-heavy workloads
- Table-level locking
- No transaction support
- Full-text search support
```sql
CREATE TABLE logs (
    id INT PRIMARY KEY
) ENGINE=MyISAM;
```

**Memory (HEAP)**
- Stores data in RAM
- Very fast
- Data lost on restart
```sql
CREATE TABLE cache (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT
) ENGINE=MEMORY;
```

### Full-Text Search

**Creating Full-Text Index**
```sql
CREATE TABLE articles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200),
    content TEXT,
    FULLTEXT(title, content)
) ENGINE=InnoDB;
```

**Searching**
```sql
-- Natural language search
SELECT * FROM articles
WHERE MATCH(title, content) AGAINST('mysql database');

-- Boolean mode search
SELECT * FROM articles
WHERE MATCH(title, content) AGAINST('+mysql -postgresql' IN BOOLEAN MODE);

-- Query expansion
SELECT * FROM articles
WHERE MATCH(title, content) AGAINST('database' WITH QUERY EXPANSION);
```

### JSON Support

**Storing JSON**
```sql
CREATE TABLE users (
    id INT PRIMARY KEY,
    profile JSON
);

INSERT INTO users VALUES (1, '{"name": "John", "age": 30, "city": "NYC"}');
```

**Querying JSON**
```sql
-- Extract value
SELECT profile->'$.name' as name FROM users;
SELECT JSON_EXTRACT(profile, '$.age') as age FROM users;

-- Search in JSON
SELECT * FROM users WHERE profile->>'$.city' = 'NYC';

-- Update JSON
UPDATE users SET profile = JSON_SET(profile, '$.age', 31) WHERE id = 1;
```

**JSON Functions**
```sql
-- JSON_OBJECT
SELECT JSON_OBJECT('name', username, 'email', email) FROM users;

-- JSON_ARRAY
SELECT JSON_ARRAY(1, 2, 3, 'test');

-- JSON_CONTAINS
SELECT * FROM users WHERE JSON_CONTAINS(profile, '"NYC"', '$.city');
```

### Window Functions (MySQL 8.0+)

**ROW_NUMBER**
```sql
SELECT
    username,
    order_total,
    ROW_NUMBER() OVER (ORDER BY order_total DESC) as rank
FROM user_orders;
```

**RANK and DENSE_RANK**
```sql
SELECT
    username,
    score,
    RANK() OVER (ORDER BY score DESC) as rank,
    DENSE_RANK() OVER (ORDER BY score DESC) as dense_rank
FROM scores;
```

**Partitioned Window Functions**
```sql
SELECT
    category,
    product_name,
    price,
    AVG(price) OVER (PARTITION BY category) as avg_category_price
FROM products;
```

**LAG and LEAD**
```sql
SELECT
    date,
    revenue,
    LAG(revenue) OVER (ORDER BY date) as previous_day,
    LEAD(revenue) OVER (ORDER BY date) as next_day
FROM daily_sales;
```

### Common Table Expressions (CTE)

**Basic CTE**
```sql
WITH user_totals AS (
    SELECT user_id, SUM(total) as total_spent
    FROM orders
    GROUP BY user_id
)
SELECT u.username, ut.total_spent
FROM users u
JOIN user_totals ut ON u.id = ut.user_id;
```

**Recursive CTE**
```sql
WITH RECURSIVE employee_hierarchy AS (
    -- Anchor member
    SELECT id, name, manager_id, 1 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive member
    SELECT e.id, e.name, e.manager_id, eh.level + 1
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.id
)
SELECT * FROM employee_hierarchy;
```

### User Management and Security

**Creating Users**
```sql
CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';
CREATE USER 'username'@'%' IDENTIFIED BY 'password';
```

**Granting Privileges**
```sql
-- All privileges
GRANT ALL PRIVILEGES ON database.* TO 'username'@'localhost';

-- Specific privileges
GRANT SELECT, INSERT, UPDATE ON database.table TO 'username'@'localhost';

-- Grant with grant option
GRANT SELECT ON database.* TO 'username'@'localhost' WITH GRANT OPTION;

-- Apply changes
FLUSH PRIVILEGES;
```

**Revoking Privileges**
```sql
REVOKE INSERT ON database.* FROM 'username'@'localhost';
REVOKE ALL PRIVILEGES ON database.* FROM 'username'@'localhost';
```

**Password Management**
```sql
-- Change password
ALTER USER 'username'@'localhost' IDENTIFIED BY 'new_password';

-- Password expiration
ALTER USER 'username'@'localhost' PASSWORD EXPIRE;
```

### Backup and Restore

**mysqldump (Logical Backup)**
```bash
# Backup single database
mysqldump -u root -p database_name > backup.sql

# Backup all databases
mysqldump -u root -p --all-databases > all_backup.sql

# Backup specific tables
mysqldump -u root -p database_name table1 table2 > tables_backup.sql

# Backup with compression
mysqldump -u root -p database_name | gzip > backup.sql.gz

# Restore
mysql -u root -p database_name < backup.sql
```

**Binary Backup**
```bash
# Using mysqlbackup (MySQL Enterprise)
mysqlbackup --backup-dir=/backup backup-and-apply-log

# Restore
mysqlbackup --backup-dir=/backup copy-back
```

### Monitoring and Troubleshooting

**Performance Monitoring**
```sql
-- Show running processes
SHOW PROCESSLIST;

-- Show full processlist
SHOW FULL PROCESSLIST;

-- Kill query
KILL QUERY 123;

-- Show status variables
SHOW STATUS LIKE 'Threads_connected';
SHOW GLOBAL STATUS LIKE 'Questions';

-- Show variables
SHOW VARIABLES LIKE 'max_connections';
```

**Slow Query Log**
```sql
-- Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;

-- Show slow queries
SELECT * FROM mysql.slow_log;
```

**Performance Schema**
```sql
-- Enable performance schema
SET GLOBAL performance_schema = ON;

-- Query statement statistics
SELECT * FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC LIMIT 10;

-- Table I/O statistics
SELECT * FROM performance_schema.table_io_waits_summary_by_table;
```

**EXPLAIN and Query Analysis**
```sql
-- Analyze query execution plan
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';

-- Extended explain
EXPLAIN EXTENDED SELECT * FROM users WHERE id > 100;
SHOW WARNINGS;

-- Analyze statement (with actual execution)
EXPLAIN ANALYZE SELECT * FROM users WHERE id > 100;
```

### Configuration Best Practices

**my.cnf / my.ini Settings**
```ini
[mysqld]
# General
max_connections = 200
max_allowed_packet = 64M
default-storage-engine = InnoDB

# InnoDB Settings
innodb_buffer_pool_size = 2G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Query Cache (5.7 and earlier)
query_cache_size = 64M
query_cache_type = 1

# Logging
slow_query_log = 1
long_query_time = 2
log_error = /var/log/mysql/error.log

# Binary Logging
log_bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7
```

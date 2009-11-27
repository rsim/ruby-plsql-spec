# example from SQL Developer 2.1 tutorial
# http://www.oracle.com/technology/obe/11gr2_db_prod/appdev/sqldev/sqldev_unit_test/sqldev_unit_test.htm

# Uncomment to create table employees2 which is used by award_bonus procedure
# plsql.execute "DROP TABLE employees2" rescue nil
# plsql.execute "CREATE TABLE employees2 AS SELECT * FROM employees WHERE ROWNUM < 0"
# plsql.execute "DROP SEQUENCE employees2_seq" rescue nil
# plsql.execute "CREATE SEQUENCE employees2_seq"

plsql.execute <<-SQL
CREATE OR REPLACE
 PROCEDURE award_bonus (
  emp_id NUMBER, sales_amt NUMBER) AS
  commission    REAL;
  comm_missing  EXCEPTION;
BEGIN
  SELECT commission_pct INTO commission
    FROM employees2
      WHERE employee_id = emp_id;

  IF commission IS NULL THEN
    RAISE comm_missing;
  ELSE
    UPDATE employees2
      SET salary = NVL(salary,0) + sales_amt*commission
        WHERE employee_id = emp_id;
  END IF;
END award_bonus;
SQL

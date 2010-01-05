# example from Code Tester for Oracle tutorial
# http://www.quest.com/code-tester-for-oracle/product-demo/chap02.htm

# Setup test tables
plsql.execute "DROP TABLE room_contents" rescue nil
plsql.execute "DROP TABLE rooms" rescue nil

plsql.execute <<-SQL
CREATE TABLE rooms (
  room_key NUMBER PRIMARY KEY,
  name VARCHAR2(100)
)
SQL
plsql.execute <<-SQL
CREATE TABLE room_contents (
  contents_key NUMBER PRIMARY KEY,
  room_key NUMBER,
  name VARCHAR2(100)
)
SQL

# Foreign key to rooms. Note: this is not a CASCADE DELETE
# key. Child data is NOT removed when the parent is
# removed.

plsql.execute <<-SQL
ALTER TABLE room_contents ADD CONSTRAINT
  fk_rooms FOREIGN KEY (room_key)
  REFERENCES rooms (room_key)
SQL

plsql.execute <<-SQL
CREATE OR REPLACE PROCEDURE remove_rooms_by_name (
  name_in IN rooms.name%TYPE)
IS
BEGIN
  IF NAME_IN IS NULL
  THEN
    RAISE PROGRAM_ERROR;
  END IF;

  DELETE FROM rooms WHERE name LIKE name_in;

END;
SQL

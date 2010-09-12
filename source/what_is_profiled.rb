plsql.execute <<-SQL
CREATE OR REPLACE PACKAGE what_is_profiled
IS
   TYPE aa1 IS TABLE OF VARCHAR2 (100)
      INDEX BY PLS_INTEGER;
   TYPE aa2 IS TABLE OF VARCHAR2 (100)
      INDEX BY PLS_INTEGER;
   PROCEDURE proc1 (arg IN NUMBER, arg2 OUT VARCHAR2);
   FUNCTION func1
      RETURN VARCHAR2;
      
      procedure driver ;
END what_is_profiled;
SQL

plsql.execute <<-SQL
CREATE OR REPLACE PACKAGE BODY what_is_profiled
IS
   TYPE p_aa1 IS TABLE OF VARCHAR2 (100)
      INDEX BY PLS_INTEGER;

   TYPE p_aa2 IS TABLE OF VARCHAR2 (100)
      INDEX BY PLS_INTEGER;

   PROCEDURE loops (arg IN NUMBER, arg2 OUT VARCHAR2)
   IS
      val
      INTEGER;
      condition1 boolean := true;
      condition2 boolean 
      := 
      true;

   BEGIN
      FOR indx IN 1 .. 100
      LOOP
         NULL;
      END LOOP;

      FOR
      indx
      IN
      1
      ..
      100
      LOOP
         val := 1;
      END
      LOOP;

      FOR indx IN 1 .. 100 LOOP NULL; END LOOP;

      FOR rec IN (SELECT *
                    FROM all_source
                   WHERE ROWNUM < 101)
      LOOP
         val := 1;
      END LOOP;

      FOR 
      rec 
      IN 
      (
      SELECT *
                    FROM all_source
                   WHERE ROWNUM < 101
      )
      LOOP
         val := 1;
      END 
      LOOP;

      WHILE (condition1 AND condition2)
      LOOP
         condition1 := FALSE;
      END LOOP;

      WHILE
      (
      condition1
      AND
      condition2
      )
      LOOP
         condition1
         := 
         FALSE
         ;
      END LOOP;

      DECLARE
         indx   INTEGER := 1;
      BEGIN
         LOOP
            EXIT WHEN indx > 100;
            indx := indx + 1;
         END LOOP;
      END;

      DECLARE
         indx   INTEGER := 1;
      BEGIN
         LOOP
            EXIT
            WHEN
            indx
            >
            100;
            indx := indx +
            1
            ;
         END LOOP;
      END;
   END;

   PROCEDURE conditionals
   IS
   a
   boolean;
   b boolean;
   c boolean
   ;
   BEGIN
      IF (a AND b OR c)
      THEN
         NULL;
         elsif
         a
         then
         null;
         else
         dbms_output.put_line ('a');
      END IF;

      a := case
      true
      when true
      then
      false
      when
      false then
      true
      else
      false
      end
      ;
      a := case true
      when true
      then
      false
      when
      false then
      true
      else
      false
      end
      ;

      case when
      sysdate > sysdate + 1
      then
      a := false;
      when 1 > 2 then
      b := false;
      when 1
      > 2
      then
      c := false;
      else null; end case;
   END;

   FUNCTION p_func1
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN NULL;
   END;

   PROCEDURE proc1 (arg IN NUMBER, arg2 OUT VARCHAR2)
   IS
   BEGIN
      NULL;
   END;

   FUNCTION func1
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN p_func1;
   END;
   
   procedure driver is
   l varchar2(100);
   begin
   loops(1, l);
   conditionals;
   proc1
   (
   1
   ,
   l);
   GOTO checkloop;
   <<checkloop>>
   dbms_output.put_line ('a');
   end;
END what_is_profiled;
SQL
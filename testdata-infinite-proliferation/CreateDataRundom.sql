-- とりあえず「種となるID群のテーブル」を作成
DROP   PROCEDURE IF EXISTS create_seed_table;
CREATE PROCEDURE create_seed_table(IN row INT)
BEGIN
	DECLARE cnt INT;
	DROP TABLE IF EXISTS id_seeds;
	CREATE TABLE id_seeds (
		uid INT AUTO_INCREMENT
		, dummy INT
		, PRIMARY KEY (uid)
	);
	-- まずは10個作る
	DROP TABLE IF EXISTS tmp_ten_rec;
  CREATE TEMPORARY TABLE tmp_ten_rec (
		uid INT AUTO_INCREMENT
		, dummy INT
		, PRIMARY KEY (uid)
	);
	SET cnt = 1;
	WHILE cnt < 8 DO
		INSERT INTO tmp_ten_rec VALUES ();
		INSERT INTO id_seeds VALUES ();
		SET cnt = cnt + 1;
	END WHILE;
	-- 次に2倍ずつ、直積かけまくる
	WHILE cnt < row DO
		INSERT INTO id_seeds (dummy) SELECT id_seeds.uid FROM id_seeds, tmp_ten_rec;
		SELECT count(*) INTO cnt FROM id_seeds;
	END WHILE;
	-- はみ出した件数は削除。
	DELETE FROM id_seeds WHERE uid > row;
END;


-- とりあえず「種となるID群のテーブル」を作成
DROP   PROCEDURE IF EXISTS create_seed_table_simple;
CREATE PROCEDURE create_seed_table_simple(IN row INT)
BEGIN
	DECLARE cnt INT;
	DROP TABLE IF EXISTS id_seeds;
	CREATE TABLE id_seeds (
		uid INT AUTO_INCREMENT
		, dummy INT
		, PRIMARY KEY (uid)
	);
	set cnt = 0;
	WHILE cnt < row DO
		INSERT INTO id_seeds VALUES ();
		SET cnt = cnt + 1;
	END WHILE;
END;

--　テーブル名からカラム情報を取得、SQLを組み立てる。
DROP   PROCEDURE IF EXISTS make_test_data_by_table_name;
CREATE PROCEDURE make_test_data_by_table_name(IN t_name VARCHAR(64))
BEGIN
	DECLARE c_name VARCHAR(64);
	DECLARE eod tinyint;
	DECLARE c_cur CURSOR FOR
		SELECT column_name
		FROM information_schema.COLUMNS
		WHERE TABLE_SCHEMA = 'gyomu_db2' AND table_name = t_name
		ORDER BY ORDINAL_POSITION;
	DECLARE continue handler FOR not found SET eod = 1;
	SET eod = 0;

	OPEN c_cur;
	FETCH c_cur INTO c_name;
	WHILE eod = 0 DO

		--　Dummy
  	SELECT t_name as tablename , c_name as columnname FROM dual;

	  FETCH c_cur INTO c_name;
	END WHILE;
	CLOSE c_cur;
END;


-- テーブルをまわす。
DROP   PROCEDURE IF EXISTS make_test_data;
CREATE PROCEDURE make_test_data()
BEGIN
	DECLARE t_name VARCHAR(64);
	DECLARE eod tinyint;
	DECLARE t_cur CURSOR FOR SELECT table_name FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'gyomu_db2' ORDER BY table_name;
	DECLARE continue handler FOR not found SET eod = 1;
	SET eod = 0;

	OPEN t_cur;
	FETCH t_cur INTO t_name;
	WHILE eod = 0 DO
		-- テーブル名を投げ込み、子関数でSQLを作らせる
		call make_test_data_by_table_name(t_name);
	  FETCH t_cur INTO t_name;
	END WHILE;
	CLOSE t_cur;
END;

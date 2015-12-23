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

-- 列一個分の「SELECT句に埋める設定」を文字列で返す。
DROP   FUNCTION IF EXISTS make_one_field_statement;
CREATE FUNCTION make_one_field_statement(
	c_name VARCHAR(64)
	, d_type VARCHAR(64)
	, c_key  VARCHAR(64)
	, char_max_length bigint(21) unsigned
	, num_pos bigint(21) unsigned
	, num_scale bigint(21) unsigned
) RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
	RETURN ('テスト');
END;

-- テーブル名からカラム情報を取得、SQLを組み立てる。
DROP   PROCEDURE IF EXISTS make_test_data_by_table_name;
CREATE PROCEDURE make_test_data_by_table_name(IN t_name VARCHAR(64) , IN s_name VARCHAR(64))
BEGIN
	DECLARE c_name VARCHAR(64);
	DECLARE d_type VARCHAR(64);
	DECLARE c_key  VARCHAR(64);
	DECLARE char_max_length bigint(21) unsigned;
	DECLARE num_pos bigint(21) unsigned;
	DECLARE num_scale bigint(21) unsigned;

	DECLARE sql VARCHAR(4096);

	DECLARE c_eod tinyint;
	DECLARE c_cur CURSOR FOR
		SELECT
			column_name
			, data_type
			, column_key
			, character_maximum_length
			, numeric_precision
			, numeric_scale
		FROM information_schema.COLUMNS
		WHERE TABLE_SCHEMA = s_name
			AND table_name = t_name
		ORDER BY ORDINAL_POSITION;
	DECLARE continue handler FOR not found SET c_eod = 1;
	SET c_eod = 0;

	-- SQLを組み立て始める
	sql = 'INSERT INTO ';


	OPEN c_cur;
	FETCH c_cur INTO c_name,d_type,c_key,char_max_length,num_pos,num_scale;
	WHILE c_eod = 0 DO

		-- Dummy
  	SELECT c_name as カラム名,d_type,c_key,char_max_length,num_pos,num_scale from dual;

		FETCH c_cur INTO c_name,d_type,c_key,char_max_length,num_pos,num_scale;
	END WHILE;
	CLOSE c_cur;
END;


-- テーブルをまわす。
DROP   PROCEDURE IF EXISTS make_test_data;
CREATE PROCEDURE make_test_data(IN s_name VARCHAR(64))
BEGIN
	DECLARE t_name VARCHAR(64);
	DECLARE eod tinyint;
	DECLARE t_cur CURSOR FOR
		SELECT table_name
		FROM information_schema.TABLES
		WHERE TABLE_SCHEMA = s_name
		ORDER BY table_name;
	DECLARE continue handler FOR not found SET eod = 1;
	SET eod = 0;

	OPEN t_cur;
	FETCH t_cur INTO t_name;
	WHILE eod = 0 DO
		-- テーブル名を投げ込み、子関数でSQLを作らせる
		call make_test_data_by_table_name(t_name, s_name);
	  FETCH t_cur INTO t_name;
	END WHILE;
	CLOSE t_cur;
END;

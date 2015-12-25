-- 文字列で設定された、一行のSQLだけを実行する
DROP   PROCEDURE IF EXISTS execute_sql_oneline;
CREATE PROCEDURE execute_sql_oneline(IN sql_statement VARCHAR(16384))
BEGIN
  SELECT sql_statement AS SQL_State FROM dual;
	SET @update_sql = sql_statement;
	PREPARE stmt from @update_sql;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
END;


-- 指定されたスキーマにあるすべてのテーブルをデストロイ(取り扱い注意)
DROP   PROCEDURE IF EXISTS destroy_them_all;
CREATE PROCEDURE destroy_them_all(IN s_name VARCHAR(64))
BEGIN
	DECLARE t_name VARCHAR(64);
	DECLARE drop_sql VARCHAR(128);
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
		-- テーブルを殺すSQLを実行。
		call execute_sql_oneline(CONCAT('DROP TABLE `', t_name, '`'));

	  FETCH t_cur INTO t_name;
	END WHILE;
	CLOSE t_cur;
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
	DECLARE seed_table_field VARCHAR(32);
	DECLARE select_field_str VARCHAR(128);
	DECLARE res_capt VARCHAR(64);

	-- シーケンスかのごとく扱う「種値テーブルのフィールド名」
	SET seed_table_field = 'id_seeds.uid';

	-- PK(もしくはユニークキー) か否か
	IF c_key IS NOT NULL THEN
		CASE d_type
			WHEN 'varchar' THEN
				SET select_field_str = CONCAT('RIGHT(CONCAT(REPEAT("0",' , char_max_length , '),' , seed_table_field , '),' , char_max_length , ')');
			WHEN 'decimal' THEN	-- NUMERICは実際には内部でDECIMALで宣言したことになるみたい
				SET select_field_str = seed_table_field;
			WHEN 'datetime' THEN
				-- 日付がPKだった場合？ とりあえず「かぶらない過去日」を作っておく
				SET select_field_str = CONCAT('ADDDATE(CURDATE() , -' , seed_table_field , ')');
			WHEN 'clob' THEN
				-- 文字列と一緒。
				SET select_field_str = CONCAT('CAST(' , seed_table_field , ' AS CHAR)');
			ELSE
				SET select_field_str = '0';
		END CASE;
	ELSE
		-- PKじゃない(平場)の場合
		CASE d_type
			WHEN 'varchar' THEN
				SET select_field_str = CONCAT('SUBSTRING(REPEAT(MD5(RAND()) , ' , char_max_length , ' / 32 + 1) , 1, ' , char_max_length , ')');
			WHEN 'decimal' THEN	-- NUMERICは実際には内部でDECIMALで宣言したことになるみたい
				SET select_field_str = CONCAT('RAND() * POW(10,' , (num_pos - num_scale) , ') - 1');
			WHEN 'datetime' THEN
				SET select_field_str = CONCAT('DATE_SUB(CURDATE() , INTERVAL (RAND() * 315360000) SECOND)');
			WHEN 'clob' THEN
				SET select_field_str = CONCAT('SUBSTRING(REPEAT(MD5(RAND()) , ' , char_max_length , ' / 32 + 1) , 1, ' , char_max_length , ')');
			ELSE
				SET select_field_str = '0';
		END CASE;
	END IF;

	RETURN select_field_str;
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

	DECLARE insert_sql VARCHAR(16384);
	DECLARE select_fields VARCHAR(16384);
	DECLARE select_field VARCHAR(128);

	DECLARE c_eod tinyint;
	DECLARE c_cur CURSOR FOR
		SELECT
			COLUMNS.column_name
			, COLUMNS.data_type
			, KEY_COLUMN_USAGE.constraint_name
			, COLUMNS.character_maximum_length
			, COLUMNS.numeric_precision
			, numeric_scale
		FROM
			information_schema.COLUMNS LEFT JOIN information_schema.KEY_COLUMN_USAGE
			ON COLUMNS.TABLE_SCHEMA = KEY_COLUMN_USAGE.TABLE_SCHEMA
			AND COLUMNS.TABLE_NAME = KEY_COLUMN_USAGE.TABLE_NAME
			AND COLUMNS.COLUMN_NAME = KEY_COLUMN_USAGE.COLUMN_NAME
		WHERE COLUMNS.table_schema = s_name
			AND COLUMNS.table_name = t_name
		ORDER BY
			COLUMNS.ORDINAL_POSITION;
	DECLARE continue handler FOR not found SET c_eod = 1;
	SET c_eod = 0;

	-- SQLを組み立て始める
	SET select_fields = '';

	OPEN c_cur;
	FETCH c_cur INTO c_name,d_type,c_key,char_max_length,num_pos,num_scale;
	WHILE c_eod = 0 DO

		IF LENGTH(select_fields) > 0 THEN
			SET select_fields = CONCAT(select_fields , ' , ');
		END IF;

		-- カラムに応じたフィールドの値生成文字列を判定し返す。
		SET select_field = make_one_field_statement(c_name,d_type,c_key,char_max_length,num_pos,num_scale);
		-- フィールドへのインサート値だけをためた文字列に継ぎ足す。
		SET select_fields = CONCAT(select_fields , select_field);

		FETCH c_cur INTO c_name,d_type,c_key,char_max_length,num_pos,num_scale;
	END WHILE;
	CLOSE c_cur;

	-- 1テーブル分の「ﾃﾞｰﾀを勝手に作る」SQLを組み立て。
	SET insert_sql = CONCAT('INSERT INTO `' , t_name , '` SELECT ' , select_fields , ' FROM id_seeds');
	-- INSERTのSQLを実行。
	call execute_sql_oneline(CONCAT('TRUNCATE TABLE `' , t_name , '`')); 	-- あらかじめ、テーブルの中身はトランケート
	call execute_sql_oneline(insert_sql);
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
		WHERE
			TABLE_SCHEMA = s_name
			AND TABLE_NAME != 'id_seeds'
		ORDER BY table_name;
	DECLARE continue handler FOR not found SET eod = 1;
	SET eod = 0;

	OPEN t_cur;
	FETCH t_cur INTO t_name;
	WHILE eod = 0 DO
		-- デバッグ表示
		SELECT t_name AS 対象テーブル名 , count(*) AS 増加件数 FROM id_seeds;
		-- テーブル名を投げ込み、子関数でSQLを作らせる
		call make_test_data_by_table_name(t_name, s_name);

	  FETCH t_cur INTO t_name;
	END WHILE;
	CLOSE t_cur;
END;

#!/bin/bash
#
# 階層があるディレクトリに入っているrarファイルをzipファイルへ変換するスクリプト。
#
# 途中で失敗するとファイルの状態がズタズタになりかねないので、
# 実行時は対象ディレクトリにバックアップをおすすめします。
#
# 前提
# - 以下のコマンドが在ることが前提
#   - find, rar, zip, rename(Ubuntu版), pushd, popd

WORK_DIR='./work/'

for i in $(find . -maxdepth 1 -type d); do
	pushd ${i}
	for j in $(ls *.rar); do
		rm -rf ${WORK_DIR}
		mkdir -p ${WORK_DIR}
		cp ${j} ${WORK_DIR}
		pushd ${WORK_DIR}
		unrar x *.rar
		rm *.rar
		# 出てきたディレクトリの半スペと括弧をリネーム
		rename 's/\ /_/g' *
		rename 's/\(//g' *
		rename 's/\)//g' *

		expand_dir=$(ls)
		result_file=${j%.rar}.zip
		zip -r ${result_file} ${expand_dir}
		rm -rf ${expand_dir}
		mv ${result_file} ../
		popd
		rm -rf ${WORK_DIR} ${j}
	done
	popd
done

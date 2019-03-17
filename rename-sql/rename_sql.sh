#!/bin/bash
#
# カレントディレクトリの *.sql 名のファイルの「ファイル名の先頭から最初に見つかった"_"から前を、連番数値に変換」しりネームを行うスクリプト。
# (flywayの命名則から、node(npm)のマイグレーションツール"postgres-migrations"形式に変換するため)
#
# 前提
# - 以下のコマンドが在ることが前提
#   - mv, let

a=1
for i in *.sql; do
  file_name_after_number=${i#*_}
  new=$(printf "%06d" "$a")_${file_name_after_number}
  mv -i -- "$i" "$new"
  let a=a+1
done

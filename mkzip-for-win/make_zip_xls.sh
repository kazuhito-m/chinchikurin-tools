#!/bin/bash
#
# 「Windows向けのZIPファイル」を作るスクリプト。
#
# 実行するディレクトリ内の「拡張子が xls のファイル」を、
# 日付フォルダに移動し、接頭辞に「月」を付け、ファイル名SJISにし、
# 「本日日付(8ケタ)のZIPファイル」に固める。

month=$(date '+%Y%m')
today=$(date '+%Y%m%d')

rm -rf ${today}
mkdir -p ${today}

for i in $(ls *.xls) ; do
    cp ${i} ${today}/${month}_${i#*_}
done

pushd ${today}
convmv -f utf8 -t sjis * --notest
pushd

zip -r ./${today}.zip ./${today}/

rm -rf ${today}
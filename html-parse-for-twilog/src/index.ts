import * as fs from 'fs';
import { JSDOM } from 'jsdom';
import { analizeTwilogHtml } from './analize-twilog-html';

const main = () => {
    const args = process.argv.slice(2); // 最初の2つを除外
    if (args.length === 0) {
        console.log("ファイル名を指定してください。");
        return;
    }
    const filePath = args[0];
    if (!fs.existsSync(filePath)) {
        console.log("指定されたファイルは存在しません。");
        return;
    }

    try {
        const html = fs.readFileSync(filePath, 'utf-8');
        const dom = new JSDOM(html);
        const document = dom.window.document;

        const posts = analizeTwilogHtml(document);

        posts.map(post => post.makeCsvOneLine())
            .forEach(line => console.log(line));
    } catch (error) {
        console.error('HTMLの解析に失敗しました。:', error);
    }
}

main();
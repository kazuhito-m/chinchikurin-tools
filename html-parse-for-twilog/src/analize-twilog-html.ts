import { XPost } from "./x-post";

export const analizeTwilogHtml = (document: Document): void => {
    const links = document.querySelectorAll('.tl-tweet');
    links.forEach((item: Element) => {
        const post = new XPost(
            nvl(item.attributes.getNamedItem('data-date')?.nodeValue),
            nvl(item.querySelector(".tl-posted .tb-tw")?.textContent),
            nvl(item.attributes.getNamedItem('data-status-id')?.nodeValue),
            nvl(item.querySelector(".tl-name span")?.textContent),
            nvl(item.querySelector(".tl-text")?.textContent)
        );

        const oneLine = [post.timestamp(), post.url(), post.fixedContent()]
            .map(i => `"${i}"`)
            .join(',');
        console.log(oneLine);
    });
}

const nvl = (value: string | null | undefined): string => {
    return value == null ? "" : value.trim();
}
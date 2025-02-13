import { XPost } from "./x-post";

export const analizeTwilogHtml = (document: Document): XPost[] => {
    return Array.from(document.querySelectorAll('.tl-tweet').values())
        .map((tlTweet: Element) => tlTweetElementToPost(tlTweet));
}

const tlTweetElementToPost = (tlTweet: Element): XPost => {
    return new XPost(
        nvl(tlTweet.attributes.getNamedItem('data-date')?.nodeValue),
        nvl(tlTweet.querySelector(".tl-posted .tb-tw")?.textContent),
        nvl(tlTweet.attributes.getNamedItem('data-status-id')?.nodeValue),
        nvl(tlTweet.querySelector(".tl-name span")?.textContent),
        nvl(tlTweet.querySelector(".tl-text")?.textContent)
    );
}

const nvl = (value: string | null | undefined): string => {
    return value == null ? "" : value.trim();
}
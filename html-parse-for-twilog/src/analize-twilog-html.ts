export const analizeTwilogHtml = (document: Document) => {
    const title = document.title;
    console.log('Title:', title);

    const links = document.querySelectorAll('a');
    links.forEach((link: { href: any; }) => {
        console.log('Link:', link.href);
    });
}
export class XPost {
    constructor(
        private readonly date: string,
        private readonly time: string,
        private readonly status: string,
        private readonly auther: string,
        private readonly content: string
    ) { }

    public timestamp(): string {
        return `${this.date}T${this.time}`;
    }

    public url(): string {
        return `https://x.com/${this.auther?.replace('@', '')}/status/${this.status}`
    }

    public fixedContent(): string {
        return this.content.replace(/"/g, "");
    }
}
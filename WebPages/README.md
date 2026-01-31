# cleanconnect Web Pages

This folder contains the required legal pages for the cleanconnect app submission to the App Store.

## Files

| File | URL to Host At |
|------|----------------|
| `privacy.md` | `thebighead.ca/cleanconnect/privacy` |
| `terms.md` | `thebighead.ca/cleanconnect/terms` |
| `support.md` | `thebighead.ca/cleanconnect/support` |

## How to Use

### Option 1: Convert to HTML
Convert the markdown files to HTML and upload to your web server:

```bash
# Using pandoc (install with: brew install pandoc)
pandoc privacy.md -o privacy.html
pandoc terms.md -o terms.html
pandoc support.md -o support.html
```

### Option 2: Use a Markdown-Enabled CMS
If your website (thebighead.ca) uses WordPress, Ghost, or another CMS that supports markdown, you can copy-paste the content directly.

### Option 3: GitHub Pages
Host these files on GitHub Pages with a Jekyll theme that renders markdown.

## Required URLs for App Store

Make sure these URLs are accessible before submitting to the App Store:

- **Privacy Policy**: `https://thebighead.ca/cleanconnect/privacy`
- **Terms of Service**: `https://thebighead.ca/cleanconnect/terms`
- **Support**: `https://thebighead.ca/cleanconnect/support`

## Company Details

- **Company**: The Bighead
- **Location**: Calgary, Alberta, Canada
- **Email**: info@thebighead.ca
- **Website**: thebighead.ca

## Key Information in Documents

| Item | Value |
|------|-------|
| Platform Fee | 7% |
| Creator Share | 93% |
| Min Tip | ₹10 |
| Max Tip | ₹10,000 |
| Data Retention | Until account deletion (7 years for transactions) |
| Governing Law | Province of Alberta, Canada |
| Contact Email | info@thebighead.ca |

## Checklist

- [ ] Upload privacy.md to thebighead.ca/cleanconnect/privacy
- [ ] Upload terms.md to thebighead.ca/cleanconnect/terms
- [ ] Upload support.md to thebighead.ca/cleanconnect/support
- [ ] Test all URLs are accessible
- [ ] Add URLs to App Store Connect listing

#!/usr/bin/env python3
"""Render an HTML file to A4 PDF using playwright chromium."""
import argparse
import os
import sys


def main():
    parser = argparse.ArgumentParser(description="Render HTML to A4 PDF")
    parser.add_argument("--html", required=True, help="Input HTML file path")
    parser.add_argument("--output", required=True, help="Output PDF file path")
    args = parser.parse_args()

    if not os.path.exists(args.html):
        print(f"Error: {args.html} not found", file=sys.stderr)
        sys.exit(1)

    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        page.goto(f"file://{os.path.abspath(args.html)}")
        page.pdf(
            path=args.output,
            format="A4",
            margin={
                "top": "16mm",
                "right": "14mm",
                "bottom": "16mm",
                "left": "14mm",
            },
            print_background=True,
        )
        browser.close()

    # Clean up temporary HTML
    os.remove(args.html)
    print(f"PDF saved to {args.output}")


if __name__ == "__main__":
    main()

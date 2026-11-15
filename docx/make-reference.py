#!/usr/bin/env python3
"""Build reference.docx: pandoc's default reference doc with the TMA page layout.

Run it after changing margins, fonts or styles. The header text contains
{{TITLE}} and {{AUTHOR}} placeholders, which ou-docx fills in from each
document's metadata after pandoc has run.
"""

import re
import subprocess
import zipfile
from pathlib import Path

OUT = Path(__file__).resolve().parent / "reference.docx"

# Twips (1/1440 inch); 1cm = 567
A4_W, A4_H = 11906, 16838
MARGIN_X = MARGIN_TOP = 2268  # 4cm, room for tutor marks
MARGIN_BOTTOM = 1417  # 2.5cm
HEADER_DIST, FOOTER_DIST = 1531, 992
HEADER_OVERHANG = 1134  # header extends 2cm into each side margin, as in the PDF
TEXT_W = A4_W - 2 * MARGIN_X

FONT = "Cambria"

W_NS = 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"'
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"


def run(text, italic=True):
    rpr = "<w:rPr><w:i/></w:rPr>" if italic else ""
    return f'<w:r>{rpr}<w:t xml:space="preserve">{text}</w:t></w:r>'


def field(instr, placeholder, italic=True):
    rpr = "<w:rPr><w:i/></w:rPr>" if italic else ""
    return (
        f'<w:r>{rpr}<w:fldChar w:fldCharType="begin"/></w:r>'
        f'<w:r>{rpr}<w:instrText xml:space="preserve"> {instr} </w:instrText></w:r>'
        f'<w:r>{rpr}<w:fldChar w:fldCharType="separate"/></w:r>'
        f"{run(placeholder, italic)}"
        f'<w:r>{rpr}<w:fldChar w:fldCharType="end"/></w:r>'
    )


# Last level-1 heading on the page (\l searches bottom-up), like the PDF header
HEADER = (
    f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:hdr {W_NS}><w:p><w:pPr>'
    f'<w:tabs><w:tab w:val="right" w:pos="{TEXT_W + HEADER_OVERHANG}"/></w:tabs>'
    f'<w:ind w:left="-{HEADER_OVERHANG}" w:right="-{HEADER_OVERHANG}"/></w:pPr>'
    + run("{{TITLE}} - ")
    + field('STYLEREF "heading 1" \\l', "Question")
    + "<w:r><w:tab/></w:r>"
    + run("{{AUTHOR}}")
    + "</w:p></w:hdr>"
)

FOOTER = (
    f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:ftr {W_NS}><w:p><w:pPr><w:jc w:val="center"/></w:pPr>'
    + field("PAGE", "1", italic=False)
    + "</w:p></w:ftr>"
)

SECT_PR = (
    "<w:sectPr>"
    '<w:headerReference w:type="default" r:id="rIdOuHeader"/>'
    '<w:footerReference w:type="default" r:id="rIdOuFooter"/>'
    '<w:footnotePr><w:numRestart w:val="eachSect"/></w:footnotePr>'
    f'<w:pgSz w:w="{A4_W}" w:h="{A4_H}"/>'
    f'<w:pgMar w:top="{MARGIN_TOP}" w:right="{MARGIN_X}" w:bottom="{MARGIN_BOTTOM}" w:left="{MARGIN_X}"'
    f' w:header="{HEADER_DIST}" w:footer="{FOOTER_DIST}" w:gutter="0"/>'
    '<w:pgNumType w:start="1"/>'
    "</w:sectPr>"
)


def set_style(styles, style_id, fn):
    pattern = re.compile(r'<w:style [^>]*w:styleId="%s".*?</w:style>' % style_id, re.S)
    return pattern.sub(lambda m: fn(m.group(0)), styles, count=1)


def set_size(style, half_points):
    style = re.sub(r'<w:sz w:val="\d+" */>', f'<w:sz w:val="{half_points}"/>', style)
    return re.sub(r'<w:szCs w:val="\d+" */>', f'<w:szCs w:val="{half_points}"/>', style)


def make_bold(style):
    return style.replace("<w:rPr>", "<w:rPr><w:b/><w:bCs/>", 1)


def fix_styles(styles):
    # One serif font everywhere instead of the theme's heading/body fonts
    styles = re.sub(
        r'<w:rFonts [^>]*Theme=[^>]*/>',
        f'<w:rFonts w:ascii="{FONT}" w:hAnsi="{FONT}" w:eastAsia="{FONT}" w:cs="{FONT}"/>',
        styles,
    )
    # Black headings
    styles = re.sub(r'<w:color [^>]*w:themeColor="accent1"[^>]*/>', "", styles)

    styles = re.sub(
        r"(<w:rPrDefault>.*?)<w:sz w:val=\"24\" */>\s*<w:szCs w:val=\"24\" */>",
        r'\1<w:sz w:val="22"/><w:szCs w:val="22"/>',
        styles,
        flags=re.S,
    )
    styles = set_style(styles, "Title", lambda s: make_bold(set_size(s, 48)))
    styles = set_style(
        styles,
        "Heading1",
        lambda s: make_bold(set_size(s, 30)).replace(
            '<w:spacing w:before="360" w:after="80" />',
            '<w:pageBreakBefore/><w:spacing w:before="0" w:after="550"/>',
        ),
    )
    styles = set_style(styles, "Heading2", lambda s: make_bold(set_size(s, 26)))
    return styles


def main():
    default = subprocess.run(
        ["pandoc", "--print-default-data-file", "reference.docx"],
        check=True,
        capture_output=True,
    ).stdout
    tmp = OUT.with_suffix(".default.docx")
    tmp.write_bytes(default)

    with zipfile.ZipFile(tmp) as src, zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as dst:
        for item in src.infolist():
            data = src.read(item.filename).decode("utf-8")
            if item.filename == "word/styles.xml":
                data = fix_styles(data)
            elif item.filename == "word/document.xml":
                data = re.sub(r"<w:sectPr>.*?</w:sectPr>", SECT_PR, data, flags=re.S)
            elif item.filename == "word/_rels/document.xml.rels":
                data = data.replace(
                    "</Relationships>",
                    f'<Relationship Type="{REL_NS}/header" Id="rIdOuHeader" Target="header1.xml"/>'
                    f'<Relationship Type="{REL_NS}/footer" Id="rIdOuFooter" Target="footer1.xml"/>'
                    "</Relationships>",
                )
            elif item.filename == "[Content_Types].xml":
                data = data.replace(
                    "</Types>",
                    '<Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>'
                    '<Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>'
                    "</Types>",
                )
            dst.writestr(item, data)
        dst.writestr("word/header1.xml", HEADER)
        dst.writestr("word/footer1.xml", FOOTER)

    tmp.unlink()
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()

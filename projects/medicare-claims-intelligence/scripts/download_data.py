"""Download the public data this project uses into data/raw and data/docs.

CMS 2008-2010 DE-SynPUF Sample 1 (beneficiary, inpatient, outpatient, Part D files),
the DE-SynPUF codebook and user manual, and CDC ILINet from the Delphi Epidata API.
"""
import io
import re
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW, DOCS = ROOT / "data" / "raw", ROOT / "data" / "docs"
CMS_PAGE = ("https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-claims-synthetic-public-use-files/"
            "cms-2008-2010-data-entrepreneurs-synthetic-public-use-file-de-synpuf/de10-sample-1")
WANTED = ["Beneficiary Summary File", "Inpatient Claims", "Outpatient Claims", "Prescription Drug Events"]
DOC_URLS = {
    "de10_codebook.pdf": "https://www.cms.gov/files/document/de-10-codebook.pdf-0",
    "synpuf_data_users_guide.pdf": "https://www.cms.gov/research-statistics-data-and-systems/downloadable-public-use-files/synpufs/downloads/synpuf_dug.pdf",
}
ILINET_URL = "https://api.delphi.cmu.edu/epidata/fluview/?regions=nat&epiweeks=201001-202652"


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=300) as r:
        return r.read()


def main():
    RAW.mkdir(parents=True, exist_ok=True)
    DOCS.mkdir(parents=True, exist_ok=True)

    html = fetch(CMS_PAGE).decode("utf-8", "ignore")
    for href, text in re.findall(r'<a[^>]+href="([^"]+\.zip)"[^>]*>(.*?)</a>', html, re.S):
        label = re.sub(r"<[^>]+>|\s+", " ", text).strip()
        if any(w.lower() in label.lower() for w in WANTED):
            url = href if href.startswith("http") else "https://www.cms.gov" + href
            print("downloading", label)
            with zipfile.ZipFile(io.BytesIO(fetch(url))) as z:
                z.extractall(RAW)

    for name, url in DOC_URLS.items():
        (DOCS / name).write_bytes(fetch(url))
    (RAW / "ilinet_national.json").write_bytes(fetch(ILINET_URL))
    print("done:", sorted(p.name for p in RAW.iterdir()))


if __name__ == "__main__":
    main()

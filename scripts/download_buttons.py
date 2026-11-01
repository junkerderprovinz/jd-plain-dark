"""The download buttons the README shows, read by gen_download_buttons.py.

Each entry names a button the generator knows and where it leads. The rows,
their order, the colours and the words are the generator's, the same in every
repository.
"""

REPO = "jd-plain-dark"

# One zip holds the theme and the installers for every system, and its name
# carries the version, so the desktop buttons lead to the release that lists it.
RELEASE = "https://github.com/junkerderprovinz/jd-plain-dark/releases/latest"

BUTTONS = {
    # The JDownloader container offers JD Plain Dark as one of its looks.
    "unraid": "https://ca.unraid.net/apps/jdownloader-18m0vwh17mexzh",
    "source": RELEASE,
    "windows": RELEASE,
    "macos": RELEASE,
    "linux": RELEASE,
}

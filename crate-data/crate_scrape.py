import os
import tarfile
import csv
import sys
import codecs
from collections import defaultdict, namedtuple
from datetime import datetime
import subprocess
import shlex
import argparse

REPORT_EXPLICIT_CMD = r"grep -or '\bdyn\b' --include='*.rs' . | wc -l"

# TODO: add debug build of rustc to Docker
REPORT_IMPLICIT_CMD = r"RUSTC=/rust/build/x86_64-unknown-linux-gnu/" \
    "stage1/bin/rustc RUSTC_LOG=rustc_codegen_ssa cargo build 2>&1 | " \
    "grep get_vtable | wc -l"

DUMP_URL = 'https://static.crates.io/db-dump.tar.gz'
CODE_DIR = 'crates'

Version = namedtuple('Version', ['id', 'num', 'downloads', 'created'])


def download(url, dest):
    """Download a file from a URL using curl.
    """
    subprocess.run(['curl', '-sLo', dest, url], check=True)


def get_dump():
    """Fetch a Crates.io data dump tarball, or reuse an existing one
    from the file system, and return its path.
    """

    tarball_fn = os.path.basename(DUMP_URL)

    if os.path.exists(tarball_fn):
        print('Using existing {}.'.format(tarball_fn), file=sys.stderr)
        return tarball_fn

    print('Downloading dump to {}...'.format(tarball_fn), file=sys.stderr)
    download(DUMP_URL, tarball_fn)
    print('...done.', file=sys.stderr)

    return tarball_fn


def parse_date(s):
    """Parse a Crates.io date/time string, returning an int.
    """
    return int(datetime.fromisoformat(s.split('.')[0]).timestamp())


def get_versions(tar, base_dir):
    """Parse versions.csv from the tarball data dump. Produce a list of
    Version objects grouped by crate ID.
    """

    versions_csv = tar.getmember(
        os.path.join(base_dir, 'data', 'versions.csv')
    )
    versions_file = codecs.getreader('utf8')(tar.extractfile(versions_csv))
    versions = defaultdict(list)
    for row in csv.DictReader(versions_file):
        crate = int(row['crate_id'])
        versions[crate].append(Version(
            int(row['id']),
            row['num'],
            int(row['downloads']),
            parse_date(row['created_at']),
        ))
    return versions


def get_crates(tar, base_dir):
    """Parse crates.csv in the data dump tarball to obtain the name for
    every crate ID.
    """

    crates_csv = tar.getmember(
        os.path.join(base_dir, 'data', 'crates.csv')
    )
    crates_file = codecs.getreader('utf8')(tar.extractfile(crates_csv))
    crate_names = {}
    for row in csv.DictReader(crates_file):
        crate_names[int(row['id'])] = row['name']
    return crate_names


def download_crate(crate, version):
    """Download and extract the source code for a crate, returning the
    path to the extracted directory.
    """

    # The tarballs on crates.io seem to use a top directory with this
    # naming pattern. Problems would definitely occur if a tarball were
    # to deviate from this pattern or not have a top-level directory...
    src_dir = os.path.join(CODE_DIR, f'{crate}-{version}')

    if os.path.isdir(src_dir):
        print(f'Already extracted {crate}.', file=sys.stderr)
        return src_dir

    # Download the archive, if it doesn't already exist.
    archive_base = f'{crate}-{version}.tar.gz'
    archive = os.path.join(CODE_DIR, archive_base)
    if os.path.exists(archive):
        print(f'Already downloaded {crate}.', file=sys.stderr)
    else:
        print(f'Downloading {crate}.', file=sys.stderr)
        url = f'https://crates.io/api/v1/crates/{crate}/{version}/download'
        download(url, archive)

    # Extract the archive.
    print(f'Extracting {crate}.', file=sys.stderr)
    subprocess.run(['tar', 'xf', archive_base], cwd=CODE_DIR, check=True)
    return src_dir


def crate_scrape(REPORT_CMD, CRATE_COUNT):
    # Apparently we got some large fields.
    csv.field_size_limit(sys.maxsize)

    # Open the tarball.
    tar = tarfile.open(get_dump(), "r:gz")
    base_dir = tar.getnames()[0]

    # Parse crate info from the tarball.
    print('Reading version data.', file=sys.stderr)
    versions = get_versions(tar, base_dir)
    print('Reading crate data.', file=sys.stderr)
    crate_names = get_crates(tar, base_dir)

    # Sum up the total download counts for each crate and sort.
    print('Finding top {} crates.'.format(CRATE_COUNT), file=sys.stderr)
    download_totals = {
        k: sum(v.downloads for v in vs)
        for k, vs in versions.items()
    }
    top_crates = sorted(download_totals.items(),
                        key=lambda p: p[1],
                        reverse=True)[:CRATE_COUNT]

    # Fetch the code for each crate.
    print('Downloading crate code.', file=sys.stderr)
    os.makedirs(CODE_DIR, exist_ok=True)
    crate_dirs = []
    for crate, downloads in top_crates:
        latest = max(versions[crate], key=lambda v: v.created)
        code_dir = download_crate(crate_names[crate], latest.num)
        crate_dirs.append((
            crate_names[crate],
            downloads,
            latest.num,
            code_dir,
        ))

    # Run the report command for each crate.
    print('Running reports.', file=sys.stderr)
    writer = csv.writer(sys.stdout)
    writer.writerow(['crate', 'downloads', 'version', 'result'])
    for crate, downloads, vers, code_dir in crate_dirs:
        cmd = REPORT_CMD
        print(f'{crate}: {cmd}', file=sys.stderr)

        try:
            proc = subprocess.run(
                cmd,
                shell=True,
                check=True,
                capture_output=True,
                cwd=code_dir,
            )
        except subprocess.CalledProcessError as exc:
            print('error:', exc, file=sys.stderr)
            out = 'error'
        else:
            out = proc.stdout.decode('utf8').strip()

        writer.writerow([crate, downloads, vers, out])


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('N', metavar='N', type=int, help='Number of crates to analyze')
    parser.add_argument("--implicit", action='store_true')
    parser.add_argument("--explicit", action='store_true')
    args = parser.parse_args()

    count = int(args.N)
    if count < 1 or count > 1000:
        print("Unexpected N", args.N,  file=sys.stderr)
        exit(1)

    if args.explicit:
        print("Checking for EXPLICIT dynamic trait usage", file=sys.stderr)
        crate_scrape(REPORT_EXPLICIT_CMD, count)

    if args.implicit:
        print("Checking for IMPLICIT dynamic trait usage", file=sys.stderr)
        crate_scrape(REPORT_IMPLICIT_CMD, count)

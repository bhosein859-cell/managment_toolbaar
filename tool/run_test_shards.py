"""Run the complete Flutter suite in isolated low-memory batches (no test exclusion).
Usage: python tool/run_test_shards.py --flutter /path/to/flutter --batch-size 2
A fresh compiler per batch avoids accumulating kernel artifacts on 2 GB hosts.
"""
import argparse
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--flutter', default='flutter')
parser.add_argument('--batch-size', type=int, default=2)
parser.add_argument('--timeout', type=int, default=180)
parser.add_argument('--output', default='docs/validation/stage17/shards')
args = parser.parse_args()
if args.batch_size < 1:
    parser.error('batch-size must be positive')
root = Path(__file__).resolve().parent.parent
os.chdir(root)
folder = root / args.output
folder.mkdir(parents=True, exist_ok=True)
files = sorted(str(p) for p in Path('test').rglob('*_test.dart'))
# Prefer disk-backed scratch, not a RAM-backed /tmp on small CI runners.
environment = os.environ.copy()
if not environment.get('TMPDIR'):
    scratch = root / '.dart_tool' / 'test-shard-tmp'
    scratch.mkdir(parents=True, exist_ok=True)
    environment['TMPDIR'] = str(scratch)
results = []
for start in range(0, len(files), args.batch_size):
    batch = files[start:start+args.batch_size]
    log = folder / f'batch-{start//args.batch_size+1:02}.txt'
    command = [args.flutter, 'test', '--no-pub', '--concurrency=1', '--reporter', 'expanded', *batch]
    with log.open('w') as output:
        process = subprocess.Popen(command, stdout=output, stderr=subprocess.STDOUT, start_new_session=True, env=environment)
        try:
            code = process.wait(timeout=args.timeout)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
            code = 124
            output.write('\nBatch terminated at timeout; not a successful run.\n')
    content = log.read_text()
    counts = re.findall(r'\+([0-9]+)(?: ~([0-9]+))?(?: -([0-9]+))?:', content)
    passed, skipped, failed = tuple(int(x or 0) for x in counts[-1]) if counts else (0, 0, 0)
    row = {'files': batch, 'exit_code': code, 'passed': passed, 'skipped': skipped, 'failed': failed, 'log': str(log.relative_to(root))}
    results.append(row)
    print(f'{log.name}: exit={code}, passed={passed}, skipped={skipped}, failed={failed}', flush=True)
    (folder / 'summary.json').write_text(json.dumps({'files_discovered': len(files), 'files_run': sum(len(r['files']) for r in results), 'passed': sum(r['passed'] for r in results), 'skipped': sum(r['skipped'] for r in results), 'all_batches_succeeded': all(r['exit_code']==0 for r in results) and sum(len(r['files']) for r in results)==len(files), 'batches': results}, indent=2)+'\n')
sys.exit(0 if all(r['exit_code']==0 for r in results) else 1)

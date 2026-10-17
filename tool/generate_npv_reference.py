"""Independent high-precision reference fixtures; run from project root.
Standard library only. Does not execute application formula strings.
"""
from decimal import Decimal, localcontext
import json
from pathlib import Path
from random import Random

rng = Random(704)
cases = []
with localcontext() as context:
    context.prec = 80
    rates = ['-0.75', '-0.10', '0', '0.05', '0.10', '1', '2']
    for index in range(50):
        initial = rng.randint(0, 5000)
        flows = [rng.randint(-1000, 2000) for _ in range(rng.randint(1, 10))]
        rate = rates[index % len(rates)]
        base = Decimal(1) + Decimal(rate)
        expected = -Decimal(initial) + sum(
            (Decimal(flow) / base ** (i + 1) for i, flow in enumerate(flows)), Decimal(0)
        )
        cases.append(dict(initial=initial, rate=rate, flows=flows, expected=str(expected)))
path = Path(__file__).resolve().parents[1] / 'test/fixtures/npv_reference.json'
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(cases, indent=2) + '\n', encoding='utf-8')
print(f'Wrote {len(cases)} Decimal reference cases.')

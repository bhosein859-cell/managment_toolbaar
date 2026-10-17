"""Independent Python Decimal oracle. Never used by the application runtime."""
from decimal import Decimal, localcontext
from pathlib import Path
import json
import random

rng = random.Random(20261016)
cases = []
with localcontext() as ctx:
    ctx.prec = 80
    for index in range(20):
        a = Decimal(rng.randint(1, 100000)) / 10
        b = Decimal(rng.randint(1, 100000)) / 100
        resources = Decimal(rng.randint(1, 12))
        for name, inputs, expected in [
            ('takt_time', {'available_time': a, 'demand': b}, a / b),
            ('production_capacity', {'available_time': a, 'ideal_cycle': b, 'parallel_resources': resources}, a / b * resources),
            ('labor_productivity', {'good_output': a, 'labor_hours': b}, a / b),
            ('cycle_time', {'run_time': a, 'total_output': b}, a / b),
            ('smed', {'before_time': b, 'after_time': a}, (b - a) / b),
            ('unit_production_cost', {'allocated_cost': a, 'good_output': b}, a / b),
            ('wip', {'throughput_rate': a, 'flow_time': b}, a * b),
            ('throughput', {'good_output': a, 'elapsed_time': b}, a / b),
            ('capacity_utilization', {'actual_output': a, 'design_capacity': b}, a / b),
        ]:
            cases.append({'id': name, 'case': index + 1, 'inputs': {key: str(value) for key, value in inputs.items()}, 'expected': str(expected)})
path = Path(__file__).resolve().parents[1] / 'test/fixtures/production_reference.json'
path.write_text(json.dumps(cases, ensure_ascii=False, indent=2) + '\n')
print(f'Wrote {len(cases)} independent Decimal references to {path.name}.')

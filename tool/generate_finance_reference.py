"""Independent high-precision reference fixtures; not an app runtime dependency."""
from pathlib import Path
from decimal import Decimal, localcontext
import json
import random

rng = random.Random(20261017)
rows = []
def put(name, inputs, value):
    rows.append({'id': name, 'inputs': {k: [str(v) for v in x] if isinstance(x, list) else str(x) for k, x in inputs.items()}, 'expected': str(value)})

with localcontext() as ctx:
    ctx.prec = 80
    for i in range(20):
        a, b = Decimal(rng.randint(1, 100000)) / 10, Decimal(rng.randint(1, 100000)) / 100
        profit = a if i % 2 else -a
        put('roi', {'net_profit': profit, 'investment': b}, profit / b)
        put('current_ratio', {'current_assets': a, 'current_liabilities': b}, a / b)
        inv, pre = a / 4, a / 8
        put('quick_ratio', {'current_assets': a, 'inventory': inv, 'prepayments': pre, 'current_liabilities': b}, (a-inv-pre)/b)
        re, rd, tax = Decimal('0.12'), Decimal('0.08'), Decimal('0.25')
        put('wacc', {'equity': a, 'debt': b, 'equity_cost': re, 'debt_cost': rd, 'tax_rate': tax}, a/(a+b)*re+b/(a+b)*rd*(1-tax))
        rate, n = Decimal(rng.randint(-50, 50)) / 100, rng.randint(0, 30)
        put('compound_interest', {'principal': a, 'period_rate': rate, 'periods': n}, a*(1+rate)**n)
        rate, n = Decimal(0) if i % 5 == 0 else Decimal(rng.randint(1, 50)) / 1000, rng.randint(1, 72)
        put('loan_payment', {'principal': a, 'period_rate': rate, 'periods': n}, a/n if rate == 0 else a*rate/(1-(1+rate)**(-n)))
        put('break_even', {'fixed_cost': a, 'unit_price': b+3, 'variable_cost': b}, a/3)
        flows = [Decimal(rng.randint(1, 500)) for _ in range(5)]
        investment = sum(flows)*Decimal('0.6')
        remaining = investment
        for j, flow in enumerate(flows):
            if flow >= remaining:
                payback = Decimal(j)+remaining/flow
                break
            remaining -= flow
        put('payback', {'initial_investment': investment, 'cash_flows': flows}, payback)
        # Construct an independent multi-period IRR oracle with a known root.
        target = Decimal(rng.randint(-50, 60))/100
        flows = [Decimal(rng.randint(1, 10000)) for _ in range(rng.randint(2, 6))]
        cf0 = -sum(flow/(1+target)**(j+1) for j, flow in enumerate(flows))
        sign = Decimal(-1) if i % 5 == 0 else Decimal(1)
        put('irr', {'cash_flows': [cf0*sign]+[f*sign for f in flows]}, target)

path = Path(__file__).resolve().parents[1] / 'test/fixtures/finance_reference.json'
path.write_text(json.dumps(rows, ensure_ascii=False, indent=2)+'\n')
print(f'Wrote {len(rows)} independent Decimal finance references.')

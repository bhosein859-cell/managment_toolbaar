"""Independent Decimal(120) sums and annual depreciation ledgers; stdlib only."""
from decimal import Decimal, localcontext
from pathlib import Path
import json
import random
D = Decimal
rng = random.Random(15002026)
rows = []
def put(id, inputs, expected, details=None):
    rows.append(dict(id=id, inputs={k:str(v) for k,v in inputs.items()}, expected=str(expected), details={k:str(v) for k,v in (details or {}).items()}))
with localcontext() as ctx:
    ctx.prec = 120
    for k in range(40):
        i = D(['0','0.1','-0.05','0.00000000000000000001','0.25','-0.5','0.03','-0.99'][k%8])
        n = [0,1,2,3,12,30,7][k%7]
        a = D(rng.randint(0,100000))
        growth = (1+i)**n
        inp = dict(amount=a,rate=i,periods=n)
        put('time_value_money',inp,a*growth,dict(interest=a*(growth-1),compound_factor=growth))
        put('inflation_adjustment',inp,a/growth,dict(deflator=1/growth))
        for id in ['future_present_factor','present_future_factor','future_annuity_factor','annuity_future_factor','present_annuity_factor','annuity_present_factor']:
            nn = max(1,n) if id in ['annuity_future_factor','annuity_present_factor'] else n
            # Explicit payments at t=1..n; no closed-form factor differences.
            fv = sum(((1+i)**(nn-t) for t in range(1,nn+1)),D(0))
            pv = sum(((1+i)**(-t) for t in range(1,nn+1)),D(0))
            factor = {'future_present_factor':lambda:(1+i)**nn,'present_future_factor':lambda:(1+i)**(-nn),'future_annuity_factor':lambda:fv,'annuity_future_factor':lambda:1/fv,'present_annuity_factor':lambda:pv,'annuity_present_factor':lambda:1/pv}[id]()
            put(id,dict(inp,periods=nn),factor,dict(converted_amount=a*factor))
        cost=D(rng.randint(100,10000));salvage=D(rng.randint(0,int(cost)));life=1+k%20;year=k%(life+1)
        data=dict(cost=cost,salvage=salvage,life=life,year=year)
        annual=(cost-salvage)/life
        end=cost;begin=cost;accum=D(0);expense=D(0)
        for t in range(year):
            begin=end;expense=annual;end-=expense;accum+=expense
        put('straight_line_depreciation',data,expense,dict(annual_depreciation=annual,book_begin=begin,book_end=end,accumulated=accum))
        d=D(['0','1','0.2','0.5','0.3333333333333'][k%5])
        end=cost;begin=cost;accum=D(0);expense=D(0)
        for t in range(year):
            begin=end;expense=min(begin*d,begin-salvage);end-=expense;accum+=expense
        put('declining_balance_depreciation',dict(data,depreciation_rate=d),expense,dict(book_begin=begin,book_end=end,accumulated=accum))
path=Path(__file__).resolve().parents[1]/'test/fixtures/engineering_economics_reference.json'
path.write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
print(f'Wrote {len(rows)} Decimal(120) references using explicit cash-flow sums and year-by-year ledgers.')

"""Independent deterministic Decimal(80) HR oracles; development only."""
from decimal import Decimal, localcontext
from pathlib import Path
import json
import random
rng=random.Random(13002026)
rows=[]
def put(id,inputs,value,**details):
    def encode(v):return [encode(x) for x in v] if isinstance(v,list) else str(v)
    rows.append(dict(id=id,inputs={k:encode(v) for k,v in inputs.items()},expected=str(value),details={k:str(v) for k,v in details.items()}))
with localcontext() as c:
    c.prec=80
    for i in range(20):
        period=[30,90,365][i%3]
        internal=Decimal(rng.randint(0,1000000));external=Decimal(rng.randint(0,1000000));n=Decimal(rng.randint(1,30));total=internal+external
        put('cost_per_hire',dict(internal_cost=internal,external_cost=external,hires=n,period_days=period),total/n,total_recruitment_cost=total)
        opening=Decimal(rng.randint(0,1000));closing=Decimal(rng.randint(1,1000));exits=Decimal(0 if i==0 else rng.randint(0,2000));avg=(opening+closing)/2
        put('employee_turnover',dict(separations=exits,opening_headcount=opening,closing_headcount=closing,period_days=period),exits/avg,average_headcount=avg)
        output=Decimal(rng.randint(0,10000))/10;hours=Decimal(rng.randint(1,2000))/10
        put('employee_productivity',dict(output=output,worked_hours=hours,period_days=period),output/hours)
        gross=Decimal(rng.randint(0,10000000));rate=[Decimal(0),Decimal('0.25'),Decimal('0.5'),Decimal('0.75'),Decimal(1)][i%5];cost=Decimal(rng.randint(1,1000000));benefit=gross*rate
        put('training_roi',dict(gross_benefits=gross,attribution_rate=rate,training_cost=cost,period_days=period),(benefit-cost)/cost,attributed_benefit=benefit,net_benefit=benefit-cost)
        days=[Decimal(rng.randint(0,1400))/2 for _ in range(rng.randint(1,10))];total=sum(days)
        put('replacement_time',dict(elapsed_days=days,period_days=period),total/len(days),total_elapsed_days=total,completed_replacements=len(days))
        hours=Decimal(0 if i==0 else rng.randint(0,1000));hour_cost=Decimal(rng.randint(1,100000));cover=Decimal(0 if hours==0 else rng.randint(0,1000000));paid=hours*hour_cost
        put('absence_cost',dict(paid_absent_hours=hours,loaded_hourly_cost=hour_cost,incremental_cover_cost=cover,period_days=period),paid+cover,paid_absence_cost=paid)
p=Path(__file__).resolve().parents[1]/'test/fixtures/hr_reference.json'
p.write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
print(f'Wrote {len(rows)} independent Decimal(80) HR references.')

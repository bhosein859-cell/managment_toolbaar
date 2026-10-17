"""Independent Python Decimal(80) / statistics oracle; never app runtime code."""
from decimal import Decimal, localcontext
from statistics import NormalDist
from pathlib import Path
import random
import json

rng = random.Random(11002026)
rows = []
def encode(v):
    if isinstance(v, list): return [encode(x) for x in v]
    return str(v)
def put(id, inputs, expected, **extra):
    rows.append(dict(id=id, inputs={k: encode(v) for k,v in inputs.items()}, expected=encode(expected), **extra))

d2 = {2: '1.128',3:'1.693',4:'2.059',5:'2.326',6:'2.534',7:'2.704',8:'2.847',9:'2.970',10:'3.078'}
with localcontext() as ctx:
    ctx.prec = 80
    for i in range(20):
        lsl = Decimal(rng.randint(-100,100)); usl=lsl+Decimal(rng.randint(1,100))
        mean=lsl+Decimal(rng.randint(-20,120))/100*(usl-lsl); sigma=Decimal(rng.randint(1,20))/10
        for id,center in [('cpk',True),('pp',False),('ppk',True)]:
            inputs={'usl':usl,'lsl':lsl,'sigma':sigma}
            if center: inputs['mean']=mean
            value=min((usl-mean)/(3*sigma),(mean-lsl)/(3*sigma)) if center else (usl-lsl)/(6*sigma)
            put(id,inputs,value)
        units=Decimal(rng.randint(10,1000)); opp=Decimal(rng.randint(1,20)); defects=Decimal(rng.randint(0,int(units*opp)))
        put('dpmo',{'defects':defects,'units':units,'opportunities':opp},defects/(units*opp)*1000000)
        dpmo=Decimal(rng.randint(1,999999));shift='none' if i%2 else 'convention_1_5'
        put('sigma_level',{'dpmo':dpmo,'shift':shift},Decimal(str(-NormalDist().inv_cdf(float(dpmo/1000000))))+(0 if shift=='none' else Decimal('1.5')))
        n=2+i%9; m=3+i%4
        data=[Decimal(rng.randint(10,100))/10 for _ in range(n*m)]
        groups=[data[j:j+n] for j in range(0,len(data),n)]
        means=[sum(g)/n for g in groups];ranges=[max(g)-min(g) for g in groups]
        cl=sum(means)/m;rbar=sum(ranges)/m;span=3*rbar/Decimal(d2[n])/Decimal(n).sqrt()
        put('xbar_control',{'subgroup_size':n,'observations':data},cl,lcl=str(cl-span),ucl=str(cl+span),means=[str(x) for x in means],ranges=[str(x) for x in ranges])
        costs=[Decimal(rng.randint(0,1000)) for _ in range(4)]
        put('coq',dict(zip(['prevention','appraisal','internal_failure','external_failure'],costs)),sum(costs))
        demand=Decimal(rng.randint(1,10000));order=Decimal(rng.randint(1,1000));holding=Decimal(rng.randint(1,100))/10
        put('eoq',{'annual_demand':demand,'order_cost':order,'holding_cost':holding},(2*demand*order/holding).sqrt())
        daily=Decimal(rng.randint(0,100));lead=Decimal(rng.randint(0,20));ss=Decimal(rng.randint(0,100))
        put('rop',{'daily_demand':daily,'lead_time':lead,'safety_stock':ss},daily*lead+ss)
        sd=Decimal(rng.randint(0,100))/10;mean_d=Decimal(rng.randint(1,100));mean_l=Decimal(rng.randint(1,10));lead_sd=Decimal(rng.randint(0,10))/10
        p=[Decimal('0.5'),Decimal('0.9'),Decimal('0.95'),Decimal('0.975'),Decimal('0.99')][i%5]
        z=Decimal(str(NormalDist().inv_cdf(float(p))))
        put('safety_stock',{'mean_demand':mean_d,'demand_sd':sd,'mean_lead':mean_l,'lead_sd':lead_sd,'service_level':p},z*(mean_l*sd*sd+mean_d*mean_d*lead_sd*lead_sd).sqrt())
        qty=[Decimal(rng.randint(0,10)) for _ in range(6)];price=[Decimal(rng.randint(0,20)) for _ in range(6)];qty[0]=10;price[0]=10
        values=[a*b for a,b in zip(qty,price)];total=sum(values);order_idx=sorted(range(6),key=lambda j:(-values[j],j));cumulative=Decimal(0);classes={}
        for j in order_idx:
            classes[str(j+1)]='C' if values[j]==0 else 'A' if cumulative/total<Decimal('0.8') else 'B' if cumulative/total<Decimal('0.95') else 'C'
            cumulative+=values[j]
        put('abc',{'annual_quantities':qty,'unit_costs':price,'a_threshold':Decimal('0.8'),'b_threshold':Decimal('0.95')},total,classes=classes,order=[j+1 for j in order_idx])
        cogs=Decimal(rng.randint(1,100000));avg=Decimal(rng.randint(1,100000));days=Decimal(rng.randint(1,365))
        put('inventory_turnover',{'cogs':cogs,'average_inventory':avg},cogs/avg)
        put('days_inventory',{'average_inventory':avg,'cogs':cogs,'period_days':days},avg/cogs*days)
        rate=Decimal(rng.randint(0,50))/100;year=Decimal(360 if i%2 else 365)
        put('inventory_holding_cost',{'average_value':avg,'annual_rate':rate,'period_days':days,'year_days':year},avg*rate*days/year)
        lot=Decimal(rng.randint(1,1000))
        put('reorder_interval',{'order_quantity':lot,'annual_demand':demand,'year_days':year},lot/demand*year)
path=Path(__file__).resolve().parents[1]/'test/fixtures/quality_inventory_reference.json'
path.write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
print(f'Wrote {len(rows)} independent quality/inventory reference cases.')

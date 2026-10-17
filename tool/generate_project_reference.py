"""Independent Decimal(80) and exhaustive path-enumeration oracle. Not runtime."""
from decimal import Decimal, localcontext
from pathlib import Path
import json
import random
rng=random.Random(12002026)
rows=[]
def encode(v):
    if isinstance(v,list):return [encode(x) for x in v]
    return str(v)
def put(id,inputs,value,**more):
    rows.append(dict(id=id,inputs={k:encode(v) for k,v in inputs.items()},expected=str(value),**more))
with localcontext() as ctx:
    ctx.prec=80
    for i in range(20):
        o=Decimal(rng.randint(0,30));m=o+Decimal(rng.randint(0,20));p=m+Decimal(rng.randint(0,30))
        inputs=dict(optimistic=o,most_likely=m,pessimistic=p)
        put('pert_duration',inputs,(o+4*m+p)/6,variance=str(((p-o)/6)**2))
        method='triangular' if i%2 else 'pert'
        value=(o+m+p)/3 if method=='triangular' else (o+4*m+p)/6
        variance=(o*o+m*m+p*p-o*m-o*p-m*p)/18 if method=='triangular' else ((p-o)/6)**2
        put('three_point',dict(inputs,method=method),value,variance=str(variance))
        pv=Decimal(rng.randint(1,1000));ev=Decimal(rng.randint(0,2000));ac=Decimal(rng.randint(1,1000))
        put('evm_performance',dict(pv=pv,ev=ev,ac=ac),ev/pv,cpi=str(ev/ac))
        put('sv_cv',dict(pv=pv,ev=ev,ac=ac),ev-pv,cv=str(ev-ac))
        method=['cpi','budget','cpi_spi','bottom_up'][i%4];bac=Decimal(rng.randint(100,10000));ev=Decimal(rng.randint(1,int(bac)));pv=Decimal(rng.randint(1,int(bac)));ac=Decimal(rng.randint(1,12000));new=Decimal(rng.randint(0,1000));remaining=bac-ev
        etc=ac*remaining/ev if method=='cpi' else remaining if method=='budget' else remaining*ac*pv/(ev*ev) if method=='cpi_spi' else new
        put('eac_etc',dict(bac=bac,pv=pv,ev=ev,ac=ac,new_etc=new,method=method),ac+etc,etc=str(etc),vac=str(bac-ac-etc))
        planned=Decimal(0 if i%5==0 else rng.randint(1,100));actual=Decimal(rng.randint(0,150))
        put('duration_comparison',dict(planned_duration=planned,actual_duration=actual),actual-planned)
    for case in range(100):
        n=1+case%9
        ids=rng.sample(range(1,1000),n)
        durations={id:Decimal(rng.randint(0,8))/2 for id in ids}
        edges=[(ids[i],ids[j]) for i in range(n) for j in range(i+1,n) if rng.random()<0.3]
        succ={id:[b for a,b in edges if a==id] for id in ids};pred={id:[a for a,b in edges if b==id] for id in ids}
        paths=[]
        def visit(path):
            if not succ[path[-1]]:paths.append(path);return
            for next in succ[path[-1]]:visit(path+[next])
        for id in ids:
            if not pred[id]:visit([id])
        lengths=[sum(durations[id] for id in path) for path in paths]
        horizon=max(lengths);critical_count=lengths.count(horizon)
        es={};ls={}
        for id in ids:
            prefix=[sum(durations[x] for x in path[:path.index(id)]) for path in paths if id in path]
            suffix=[sum(durations[x] for x in path[path.index(id):]) for path in paths if id in path]
            es[id]=max(prefix);ls[id]=horizon-max(suffix)
        tf={id:ls[id]-es[id] for id in ids};ff={id:min((es[x] for x in succ[id]),default=horizon)-es[id]-durations[id] for id in ids}
        rng.shuffle(ids)
        inputs=dict(activity_ids=ids,durations=[durations[id] for id in ids],predecessor_ids=[a for a,b in edges],successor_ids=[b for a,b in edges])
        details={name:[str(v[id]) for id in ids] for name,v in [('es',es),('ef',{id:es[id]+durations[id] for id in ids}),('ls',ls),('lf',{id:ls[id]+durations[id] for id in ids}),('total_float',tf),('free_float',ff)]}
        put('cpm',inputs,horizon,details=details,critical_count=critical_count)
        put('project_float',inputs,max(tf.values()),details=details,critical_count=critical_count)
path=Path(__file__).resolve().parents[1]/'test/fixtures/project_reference.json'
path.write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
print(f'Wrote {len(rows)} cases: 120 Decimal scalar and 200 exhaustive-path network references.')

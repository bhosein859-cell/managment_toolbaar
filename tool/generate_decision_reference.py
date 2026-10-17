"""Independent Decimal(80) oracles, closed-form 3x3 AHP, tree policy enumeration."""
from pathlib import Path
from decimal import Decimal, localcontext
import itertools
import random
import json
rng=random.Random(14002026)
D=Decimal
rows=[]
def encode(x):
    if isinstance(x,list):return [encode(v) for v in x]
    return str(x)
def put(id,inputs,expected,details=None):
    rows.append(dict(id=id,inputs={k:encode(v) for k,v in inputs.items()},expected=str(expected),details={k:encode(v) for k,v in (details or {}).items()}))
def normalized(w):return [v/sum(w) for v in w]
def pairwise(w):return [a/b for a in w for b in w]
def minmax(a,directions):
    cols=list(zip(*a));u=[[D(0) for _ in cols] for _ in a]
    for j,col in enumerate(cols):
        lo,hi=min(col),max(col)
        if lo!=hi:
            for i in range(len(a)):u[i][j]=((a[i][j]-lo) if directions[j]==1 else (hi-a[i][j]))/(hi-lo)
    return u
def score(a,w):return [sum(v*x for v,x in zip(row,w)) for row in a]
with localcontext() as ctx:
    ctx.prec=80
    for case in range(20):
        n=2+case%5;m=2+case%4
        a=[[D(rng.randint(-10,20)) for _ in range(m)] for _ in range(n)]
        for i in range(n):a[i][0]=D(i+1)
        if case%4==0:
            for row in a:row[-1]=D(5)
        weights=[D(rng.randint(0,5)) for _ in range(m)];weights[0]=D(1)
        directions=[rng.choice([1,-1]) for _ in range(m)];w=normalized(weights);u=minmax(a,directions)
        inp=dict(alternatives=n,criteria=m,matrix=[v for row in a for v in row],weights=weights,directions=directions)
        scores=score(u,w);put('decision_matrix',inp,max(scores),dict(scores=scores,normalized_weights=w,normalized_matrix=[v for r in u for v in r]))
        raw=score(a,w);put('weighted_scoring',{k:v for k,v in inp.items() if k!='directions'},max(raw),dict(scores=raw,normalized_weights=w))
        positive=[[v+D(11) for v in row] for row in a]
        norm=[sum(row[j]**2 for row in positive).sqrt() for j in range(m)]
        weighted=[[row[j]/norm[j]*w[j] for j in range(m)] for row in positive]
        best=[(max if directions[j]==1 else min)(row[j] for row in weighted) for j in range(m)]
        worst=[(min if directions[j]==1 else max)(row[j] for row in weighted) for j in range(m)]
        dp=[sum((row[j]-best[j])**2 for j in range(m)).sqrt() for row in weighted]
        dm=[sum((row[j]-worst[j])**2 for j in range(m)).sqrt() for row in weighted]
        scores_t=[y/(x+y) for x,y in zip(dp,dm)]
        put('topsis',dict(inp,matrix=[v for row in positive for v in row]),max(scores_t),dict(scores=scores_t,normalized_weights=w,distance_plus=dp,distance_minus=dm))
        selected=case%m
        if sum(weights)-weights[selected]==0:weights[(selected+1)%m]=D(1)
        w=normalized(weights);base=score(u,w);sweep=[D(0),D('0.25'),D('0.5'),D('0.75'),D(1)];detail=dict(scores=base,baseline_weights=w)
        for k,t in enumerate(sweep):
            nw=[t if j==selected else (1-t)*weights[j]/(sum(weights)-weights[selected]) for j in range(m)]
            detail[f'scenario_{k+1}_scores']=score(u,nw)
        put('weight_sensitivity',dict(inp,weights=weights,selected_criterion=selected+1,sweep_weights=sweep),max(base),detail)
        an=2+case%4;cn=2+case%4
        cw=[D(rng.randint(1,5)) for _ in range(cn)];local=[[D(rng.randint(1,5)) for _ in range(an)] for _ in range(cn)];cw_norm=normalized(cw);local_norm=[normalized(x) for x in local]
        final=[sum(cw_norm[j]*local_norm[j][i] for j in range(cn)) for i in range(an)]
        put('ahp',dict(alternatives=an,criteria=cn,criteria_matrix=pairwise(cw),local_matrices=[v for x in local for v in pairwise(x)]),max(final),dict(scores=final,criteria_weights=cw_norm,local_priorities=[v for row in local_norm for v in row],consistency_ratio=[D(0)]*(cn+1)))
        # Arbitrary reciprocal 3x3 matrices: row geometric means equal principal eigenvector.
        a12,a13,a23=[D(rng.choice(['0.2','0.5','1','2','3','5'])) for _ in range(3)]
        cm=[D(1),a12,a13,1/a12,D(1),a23,1/a13,1/a23,D(1)]
        geom=[ctx.power(cm[i*3]*cm[i*3+1]*cm[i*3+2],D(1)/3) for i in range(3)];eigen=normalized(geom)
        lam=sum(sum(cm[i*3+j]*eigen[j] for j in range(3))/eigen[i] for i in range(3))/3
        cr=(lam-3)/2/D('0.58');global_score=[eigen[0]*D('0.8')+eigen[1]*D('0.5')+eigen[2]*D('0.25'),eigen[0]*D('0.2')+eigen[1]*D('0.5')+eigen[2]*D('0.75')]
        put('ahp',dict(alternatives=2,criteria=3,criteria_matrix=cm,local_matrices=pairwise([D(4),D(1)])+pairwise([D(1),D(1)])+pairwise([D(1),D(3)])),max(global_score),dict(scores=global_score,criteria_weights=eigen,consistency_ratio=[max(D(0),cr),D(0),D(0),D(0)]))
        ca=D(rng.randint(0,100));cb=D(rng.randint(0,100));ba=D(rng.randint(0,200));bb=D(rng.randint(0,200));da=ba-ca;db=bb-cb
        det=dict(net_a=da,net_b=db)
        if ca>0:det['bcr_a']=ba/ca
        if cb>0:det['bcr_b']=bb/cb
        put('cost_benefit_comparison',dict(cost_a=ca,benefit_a=ba,cost_b=cb,benefit_b=bb,period_days=365),db-da,det)
        fa=D(rng.randint(0,100));fb=fa+D(rng.randint(1,100));vb=D(rng.randint(0,10));va=vb+D(rng.randint(1,10));q=(fb-fa)/(va-vb)
        put('two_option_break_even',dict(fixed_a=fa,fixed_b=fb,variable_a=va,variable_b=vb,period_days=365),q,dict(cost_a=fa+va*q,cost_b=fb+vb*q))
        # General binary depth-3 trees; oracle enumerates all decision policies.
        ids=rng.sample(range(1,10000),15);types={};payoffs={};edges=[];children={x:[] for x in ids}
        for index,id in enumerate(ids):
            terminal=index>=7;kind=0 if terminal else rng.choice([1,2]);types[id]=kind;payoffs[id]=D(rng.randint(-100,200)) if terminal else D(0)
            if not terminal:
                probs=[D('0.25'),D('0.75')] if kind==1 else [D(1),D(1)]
                for child,prob in zip([ids[2*index+1],ids[2*index+2]],probs):edges.append((id,child,prob));children[id].append((child,prob))
        def optimal(subroot):
            reachable=[]
            def collect(id):
                reachable.append(id)
                for child,p in children[id]:collect(child)
            collect(subroot);decisions=[x for x in reachable if types[x]==2]
            def evaluate(id,policy):
                if types[id]==0:return payoffs[id]
                if types[id]==2:return evaluate(children[id][policy[id]][0],policy)
                return sum(p*evaluate(child,policy) for child,p in children[id])
            return max(evaluate(subroot,dict(zip(decisions,policy))) for policy in itertools.product([0,1],repeat=len(decisions)))
        node_values={id:optimal(id) for id in ids};shuffled=ids[:];rng.shuffle(shuffled)
        put('expected_value_tree',dict(root_id=ids[0],node_ids=shuffled,node_types=[types[x] for x in shuffled],payoffs=[payoffs[x] for x in shuffled],from_ids=[x for x,y,p in edges],to_ids=[y for x,y,p in edges],probabilities=[p for x,y,p in edges]),node_values[ids[0]],dict(node_values=[node_values[x] for x in shuffled]))
p=Path(__file__).resolve().parents[1]/'test/fixtures/decision_reference.json';p.write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
print(f'Wrote {len(rows)} independent references: Decimal matrices, 3x3 AHP closed forms, tree policy enumeration.')

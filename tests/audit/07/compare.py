import json,re
L=open('G:/tst/NeonWarlords/review/gdd/00_full_gdd.txt',encoding='utf-8').read().split('\n')[1711:2087]
d=json.load(open('G:/tst/NeonWarlords/data/gdd.json',encoding='utf-8'))
# player levels
pl={}
for ln in L:
    c=[x.strip() for x in ln.split('|')]
    if len(c)==9 and c[0].isdigit():
        for i in (0,3,6):
            if c[i]: pl[int(c[i])]=(int(c[i+1].replace(',','')),c[i+2])
    if len(c)==9 and c[0]=='' and c[6].isdigit(): pl[int(c[6])]=(int(c[7].replace(',','')),c[8])
bad=0
for r in d['playerLevels']:
    g=pl.get(r[0])
    if g is None or g[0]!=r[1] or g[1]!=r[2]: bad+=1; print('PL',r,g)
print('playerLevels',len(pl),len(d['playerLevels']),'mismatch',bad)
# login
i=[k for k,x in enumerate(L) if x.startswith('Mon | Tues')][0]
lg=[]
for x in L[i+1:i+6]: lg+= [c.strip() for c in x.split('|')]
lg=[x for x in lg if x!='N/A']
print('login equal', lg==d['login'], len(lg))
for a,b in zip(lg,d['login']):
    if a!=b: print(' LG',a,b)
# jobs
i=[k for k,x in enumerate(L) if x.startswith('Jobs | Rewards')][0]
per=None; jobs={'daily':[],'weekly':[],'monthly':[]}
for x in L[i+1:]:
    if x.startswith('</TABLE>'): break
    if x.strip() in ('Daily','Weekly','Monthly'): per=x.strip().lower(); continue
    jobs[per].append([c.strip() for c in x.split(' | ')])
for p in jobs:
    for a,b in zip(jobs[p],d['jobs'][p]):
        if a!=b: print(' JOB',p,a,b)
    print('jobs',p,len(jobs[p]),len(d['jobs'][p]))
# ambitions
tabs=[k for k,x in enumerate(L) if x.startswith('Tier | Order | Ambition')]
for k,cat in zip(tabs,['Campaign','Hideout','Equipment','Reputation','Warlord','Bastion & Pit']):
    rows=[]
    for x in L[k+1:]:
        if x.startswith('</TABLE>'): break
        c=[y.strip() for y in x.split(' | ')]
        rows.append([int(c[0]),int(c[1]),c[2],c[3]])
    j=d['ambitions'][cat]
    print('amb',cat,len(rows),len(j))
    for a,b in zip(rows,j):
        if a!=b: print('  AMB',a,'\n     ',b)

# Compare GDD section 13 text (login, jobs, ambitions) against data/gdd.json.
import json, re, sys
L = [l.rstrip('\n') for l in open('review/gdd/13_login-jobs-ambitions-safehouse.txt', encoding='utf-8')]
cells = [re.sub(r'^\[[^\]]*\]\s?', '', l).strip() for l in L]
d = json.load(open('data/gdd.json', encoding='utf-8'))
bad = 0
# login: cells after "Sun" up to "Jobs and Rewards" heading, minus N/A
i = cells.index('Sun') + 1
j = cells.index('Jobs and Rewards')
login = [c for c in cells[i:j] if c and c != 'N/A']
if login != d['login']:
    bad += 1; print('LOGIN MISMATCH', login, d['login'])
print('login days', len(login))
# jobs
k = cells.index('Rewards', cells.index('Jobs and Rewards Table')) + 1
end = cells.index('Ambitions (Lifetime Missions)')
period = None; jobs = {'daily': [], 'weekly': [], 'monthly': []}
seq = [c for c in cells[k:end] if c]
n = 0
while n < len(seq):
    if seq[n] in ('Daily', 'Weekly', 'Monthly'):
        period = seq[n].lower(); n += 1; continue
    jobs[period].append([seq[n], seq[n+1]]); n += 2
for p in jobs:
    if jobs[p] != d['jobs'][p]:
        bad += 1; print('JOB MISMATCH', p)
    print(p, len(jobs[p]))
# ambitions: each table "<X> Ambitions Table and Rewards" Tier Order Desc Rewards then 4-tuples
heads = [ix for ix, c in enumerate(cells) if c.endswith('Ambitions Table and Rewards')]
heads.append(cells.index('Safehouse Upgrade'))
for h in range(len(heads) - 1):
    name = cells[heads[h]].replace(' Ambitions Table and Rewards', '')
    seq = [c for c in cells[heads[h] + 5:heads[h + 1]] if c]
    rows = []
    q = 0
    while q + 3 < len(seq) and seq[q].isdigit():
        rows.append([int(seq[q]), int(seq[q+1]), seq[q+2], seq[q+3]]); q += 4
    key = {'Bastion and Pit': 'Bastion & Pit'}.get(name, name)
    js = [[int(r[0]), int(r[1]), r[2], r[3]] for r in d['ambitions'][key]]
    if rows != js:
        bad += 1; print('AMB MISMATCH', name)
        for a, b in zip(rows, js):
            if a != b: print('  gdd', a, '\n  code', b)
    print(name, len(rows), 'rows')
    descs = [r[2] for r in rows]
    for dsc in set(descs):
        if descs.count(dsc) > 1: print('  DUPLICATE DESC in GDD:', dsc, [r[:2] for r in rows if r[2] == dsc])
print('mismatches:', bad)

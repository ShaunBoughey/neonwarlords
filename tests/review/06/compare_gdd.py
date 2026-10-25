# Compares review/gdd/06_city-campaign.txt tables against data/gdd.json (campaign + campaignProgress).
import json, re, sys
lines = [l.rstrip('\n') for l in open('review/gdd/06_city-campaign.txt', encoding='utf-8')]
cells = [re.sub(r'^\[[^\]]*\]\s?', '', l).strip() for l in lines]
J = json.load(open('data/gdd.json'))
num = lambda s: int(s.replace(',', ''))
errs = []
# reward table
i = cells.index('Slums')
locs = []
for L in range(10):
    name = cells[i]; setname = cells[i+7]; i += 8
    stages = []
    for s in range(7):
        assert cells[i].startswith('Stage %d:%d' % (L+1, s+1)), cells[i]
        v = [num(x) for x in cells[i+1:i+7]]; slot = cells[i+7]
        stages.append((v, slot)); i += 8
    locs.append((name, setname, stages))
for L, (name, setname, stages) in enumerate(locs):
    c = J['campaign'][L]
    if c['name'] != name: errs.append('loc %d name gdd=%s json=%s' % (L+1, name, c['name']))
    if c['set'] != setname: errs.append('loc %d set gdd=%s json=%s' % (L+1, setname, c['set']))
    for s, (v, slot) in enumerate(stages):
        js = c['stages'][s]
        if js['slot'] != slot: errs.append('%d:%d slot gdd=%s json=%s' % (L+1, s+1, slot, js['slot']))
        for d in range(3):
            if js['rew'][d] != v[2*d:2*d+2]: errs.append('%d:%d d%d rew gdd=%s json=%s' % (L+1, s+1, d, v[2*d:2*d+2], js['rew'][d]))
# enemy table
i = cells.index('Campaign Enemy Warlord Levels')
i = cells.index('Slums', i) + 10
for L in range(10):
    if L > 0:
        assert cells[i] == locs[L][0], (cells[i], locs[L][0]); i += 10
    for s in range(7):
        assert cells[i] == 'Stage %d:%d' % (L+1, s+1), cells[i]
        v = [num(x) for x in cells[i+1:i+10]]; i += 10
        js = J['campaign'][L]['stages'][s]['enemy']
        for d in range(3):
            if js[d] != v[3*d:3*d+3]: errs.append('%d:%d d%d enemy gdd=%s json=%s' % (L+1, s+1, d, v[3*d:3*d+3], js[d]))
print('reward+enemy mismatches:', len(errs)); print('\n'.join(errs))
# progression
i = cells.index('Campaign Progression Rewards'); i = cells.index('Warlord', i) + 1
prog = []
while cells[i]:
    prog.append((num(cells[i]), cells[i+1:i+4])); i += 4
print(json.dumps(J['campaignProgress'])[:3000])
for p in prog: print(p)

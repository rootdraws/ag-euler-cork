# AG-Euler

Alpha Growth's Euler deployment monorepo. Each subdirectory is a partner deployment — custom contracts, deployment scripts, and docs. One frontend ([ag-euler-lite](https://github.com/rootdraws/ag-euler-lite)), configured per partner via env vars in Vercel.

See [MONOREPO.md](MONOREPO.md) for architecture, deployment pipeline, and how to add a new partner.

---

## Deployments

| Partner | URL | Contracts | Status |
|---|---|---|---|
| Cork Protocol | [cork.alphagrowth.fun](https://cork.alphagrowth.fun) | [cork-contracts/](cork-contracts/) | Live |
| Balancer | balancer.alphagrowth.fun | balancer/ | Planned |

---

## Structure

```
AG-Euler/
├── cork-contracts/          ← Cork Protocol deployment
│   ├── src/                 ← oracle, hook, liquidator, vault
│   ├── script/              ← 7 deployment scripts
│   ├── cork-README.md
│   ├── cork-implementation.md
│   └── cork-claude.md
├── reference/               ← upstream read-only repos (submodules)
│   ├── ethereum-vault-connector/
│   ├── euler-interfaces/
│   ├── euler-labels/
│   ├── euler-vault-kit/
│   ├── euler-vault-scripts/
│   └── phoenix/
├── euler-lite/              ← frontend (independent repo → rootdraws/ag-euler-lite)
├── claude.md                ← AG-wide frontend context
├── MONOREPO.md              ← architecture + deployment SOP
└── README.md
```

## Clone

```bash
git clone --recurse-submodules https://github.com/rootdraws/ag-euler.git
```

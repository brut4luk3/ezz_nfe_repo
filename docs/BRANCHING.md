# Política de Branches e Ambientes

## Branches
- `dev`: desenvolvimento diário. Todo trabalho novo começa aqui.
- `main`: produção. Só recebe merge de release.

## Regras
- Todo desenvolvimento ocorre na `dev`.
- A `main` só recebe merge vindo da `dev` quando for release.

## Relação Branch → Flavor → Firebase
- `dev` → flavor `dev` → Firebase `ezz-nfe-dev`
- `main` → flavor `prod` → Firebase `ezz-nfe-prod`

## Comandos Git (fluxo básico)

### Criar branch `dev`
```bash
git checkout -b dev
```

### Trocar de branch
```bash
git checkout dev
# ou
git checkout main
```

### Merge de `dev` para `main` (release)
```bash
git checkout main
git merge dev
```

FROM node:20-alpine

WORKDIR /app

# pnpm viene con Node vía corepack, no hace falta instalarlo aparte
RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile

COPY src ./src

ENV NODE_ENV=production

# Cloud Run setea PORT en runtime; 8080 es el default/documentado.
EXPOSE 8080

CMD ["node", "src/index.js"]

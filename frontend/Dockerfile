# --- Stage 1: build ---
FROM node:20-alpine AS build

WORKDIR /app
RUN corepack enable && corepack prepare pnpm@10.5.2 --activate

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

# La URL del backend se fija en build-time (SPA estática): la pasa el
# pipeline de CI/CD como build-arg, no queda hardcodeada en el repo.
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL
RUN pnpm build

# --- Stage 2: serve ---
FROM nginx:1.27-alpine

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Cloud Run espera que el contenedor escuche en $PORT (default 8080,
# fijado también en nginx.conf ya que nginx no puede leer env vars en su
# config sin envsubst adicional; 8080 es el puerto documentado de Cloud Run).
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]

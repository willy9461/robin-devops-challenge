# --- Stage 1: build ---
# Necesita shell + pnpm para resolver dependencias, así que usa una
# imagen normal, no distroless. Solo se instalan dependencias de
# producción (sin devDependencies).
FROM node:22-alpine AS build

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@10.5.2 --activate

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile

COPY src ./src

# --- Stage 2: production (distroless) ---
# Sin shell, sin gestor de paquetes, sin nada más que el runtime de
# Node — reduce la superficie de ataque: si alguien lograra ejecutar
# código arbitrario en el contenedor, no tendría con qué moverse (no
# hay sh, no hay apk/apt).
FROM gcr.io/distroless/nodejs22-debian12:nonroot

WORKDIR /app

# Solo lo necesario para correr: node_modules ya resueltos + el código.
# Nada de código de build, configs, ni herramientas de dev.
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/src ./src

ENV NODE_ENV=production

# El tag :nonroot ya corre como UID 65532 por default — no hace falta
# crear un usuario a mano, como sí requería el runtime anterior con
# alpine (ver estado anterior de este archivo en git).

# Cloud Run setea PORT en runtime; 8080 es el default/documentado.
EXPOSE 8080

# La imagen distroless de Node ya tiene el binario de node como
# entrypoint fijo (no hay shell para invocarlo de otra forma) — el CMD
# es directamente el path al archivo, sin "node" adelante.
CMD ["src/index.js"]

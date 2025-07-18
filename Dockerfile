# ---------------------
# Etapa 1: Build
# ---------------------
FROM python:3.9-slim-bookworm AS builder

WORKDIR /app

# Copiar archivos necesarios primero (mejor cacheo)
COPY requirements.txt .

# Actualizar sistema y preparar entorno de build
RUN apt-get update && apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends gcc && \
    pip install --upgrade pip && \
    pip install --prefix=/install -r requirements.txt && \
    apt-get purge -y --auto-remove gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------
# Etapa 2: Runtime
# ---------------------
FROM python:3.9-slim-bookworm

# Crear usuario sin privilegios
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser

WORKDIR /app

# Copiar aplicación y dependencias precompiladas
COPY --from=builder /install /usr/local
COPY . .

# Establecer variable de entorno
ENV PORT=80

# Cambiar al usuario seguro
USER appuser

# Puerto expuesto (opcional, útil para documentación)
EXPOSE 80

# Comando final
CMD ["gunicorn", "--bind", ":80", "--workers", "1", "--threads", "8", "main:app"]

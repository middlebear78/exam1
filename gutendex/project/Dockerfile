 # ---- Stage 1: Builder (compiles dependencies, then gets thrown away) ----                                                                                                                   
  FROM python:3.9-slim AS builder                                                                                                                                                             
                                                                                                                                                                                                
  # Install system dependencies for psycopg2 - the adaptor between django and postgres                                                                                                          

  # psycopg2 compiles from C source code. It needs:
    # - gcc: the C compiler
    # - libpq-dev: PostgreSQL connection library
   
    # - libc-dev: basic C language building blocks (like limits.h)  - this was missing for me
   
  RUN apt-get update && apt-get install -y --no-install-recommends \
      gcc \
      libpq-dev \
      libc-dev \
      && rm -rf /var/lib/apt/lists/*

  WORKDIR /app

  COPY requirements.txt .
  RUN pip install --no-cache-dir -r requirements.txt

  # ---- Stage 2: Final image (only runtime, no build tools) ----
  # Changed from python:3.9-slim (Debian ~125MB) to python:3.9-alpine (Alpine ~50MB)
  # Alpine is a much smaller Linux distribution, saves ~75MB
  # Also means we use apk instead of apt-get, and different package names
  # FROM python:3.9-slim  # <-- previous image, kept for reference
  FROM python:3.9-alpine

  # Runtime dependencies only (no gcc, no dev headers - much smaller)
    # - libpq5: PostgreSQL runtime library (lighter than libpq-dev)
    #   NOTE: in Alpine the package is called "libpq" not "libpq5"
    # - rsync: used by the updatecatalog management command
    # - bzip2: for decompressing the catalog, it failed silently before after i check the logs ...
    # - postgresql-client: commented out to reduce image size (~80MB savings)
    #   was used for psql SELECT 1 test in entrypoint -  i removed it because i wanted to make the image smaller , the healthcheck iin the docker compose is suffiecient for this ...
    #   healthcheck in docker-compose handles DB readiness instead
  
    # Previous apt-get command (Debian/slim):
  # RUN apt-get update && apt-get install -y --no-install-recommends \
  #     libpq5 rsync bzip2 && rm -rf /var/lib/apt/lists/*
  RUN apk add --no-cache \
      libpq \
      rsync \
      bzip2

  WORKDIR /app

  # Copy compiled Python packages from builder (no gcc needed anymore)
  COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
  COPY --from=builder /usr/local/bin /usr/local/bin

  COPY . .

  RUN chmod +x entrypoint.sh
 

  EXPOSE 8000

  ENTRYPOINT ["./entrypoint.sh"]
  CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
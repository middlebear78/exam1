FROM python:3.9-slim


# Install system dependencies for psycopg2 - the adaptor between django and postgres 

# psycopg2 compiles from C source code. It needs:                                                                                                                                             
  # - gcc: the C compiler                                                                                                                                                                     
  # - libpq-dev: PostgreSQL connection library                                                                                                                                                  
  # - libc-dev: basic C language building blocks (like limits.h)  - this was missing for me                                                                                                                            
  # - rsync: used by the updatecatalog management command
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    libc-dev \
    rsync \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . . 

RUN chmod +x entrypoint.sh    

EXPOSE 8000

ENTRYPOINT ["./entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
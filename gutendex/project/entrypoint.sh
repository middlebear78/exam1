#!/bin/sh                                                                                                                                                                                     
# Entrypoint script for the Gutendex backend container.                                                                                                                                     
# Runs setup tasks before starting the Django server.                                                                                                                                         
# Docker healthcheck ensures DB is ready, but we verify as a safety net.                                                                                                                      
set -e

# DB connection test - commented out to reduce image size (postgresql-client removed ~80MB)
# healthcheck in docker-compose handles DB readiness instead
# echo "Testing database connection..."
# until psql -h "$DATABASE_HOST" -p "$DATABASE_PORT" -U "$DATABASE_USER" -d "$DATABASE_NAME" -c "SELECT 1;"; do
#     echo "Database not responding to queries, retrying in 2s..."
#     sleep 2
# done
# echo "Database responded successfully!"

# Apply database migrations (creates/updates tables, safe to run multiple times)
echo "Applying migrations..."
python manage.py migrate --noinput

# Load catalog data on first run only
# The flag file persists on the Docker volume, so restarts skip this step
if [ ! -f /app/catalog_files/.catalog_loaded ]; then
    echo "First run detected. Loading catalog data (this may take a few minutes)..."
    python manage.py updatecatalog
    touch /app/catalog_files/.catalog_loaded
    echo "Catalog data loaded."
fi

# Collect static files into the shared volume for Nginx to serve - collectstatic is a django management command 
echo "Collecting static files..."
python manage.py collectstatic --noinput

#REMOVE THE STATIC FILES FROM THE APP CONTAINER AFTER COPYING THEM TO THE STATIC VOLUME 
rm -rf /app/static/

# -Hand off to the CMD from Dockerfile (starts the server)
# exec replaces this shell process with the server process
exec "$@"
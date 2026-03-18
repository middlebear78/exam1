#!/bin/sh                                                                                                                                                                                     
# Entrypoint script for the Gutendex backend container.                                                                                                                                     
# Runs setup tasks before starting the Django server.                                                                                                                                         
# Docker healthcheck ensures DB is ready, but we verify as a safety net.                                                                                                                      
set -e

# Verify database connection (backup check in case healthcheck is bypassed)
echo "Verifying database connection..."
until python manage.py check --database default; do
    echo "Database not ready, retrying in 2s..."
    sleep 2
done
echo "Database connection verified."

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

# Collect static files into the shared volume for Nginx to serve
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Hand off to the CMD from Dockerfile (starts the server)
# exec replaces this shell process with the server process
exec "$@"
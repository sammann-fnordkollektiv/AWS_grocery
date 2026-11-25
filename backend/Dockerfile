################################################################################
# BUILDTIME
################################################################################
# Most lightweight python 3.11. available. 
# Security: Version pinning with 3.11.18
FROM python:3.11.18-alpine3.24 AS buildtime

# Optimize: Setting up a venv in buildtime makes COPY into runtime faster
ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH"

# Security: Build with app user to minimize risks from unknown dependencies
RUN addgroup -S appuser \
    && adduser -S -G appuser -h /home/appuser appuser \
    && install -d -o appuser -g appuser /opt/venv /app

WORKDIR /app

# Security: change to appuser
USER appuser

COPY --chown=appuser:appuser backend/requirements.txt ./requirements.txt
RUN python -m venv "$VIRTUAL_ENV" \
    && python -m pip install --no-cache-dir --requirement requirements.txt

COPY --chown=appuser:appuser backend/ /app/backend/
COPY --chown=appuser:appuser frontend/ /app/frontend/


################################################################################
# RUNTIME
################################################################################

FROM python:3.11.18-alpine3.24 AS runtime

# Do not write pyc and save space: PYTHONDONTWRITEBYTECODE=1
# Optimize Logging (disable buffering): PYTHONUNBUFFERED=1
ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Security: Runtime also with app user to minimize risks from unknown states
ARG APP_UID=1000
ARG APP_GID=1000

RUN addgroup -S -g "$APP_GID" appuser \
    && adduser -S -u "$APP_UID" -G appuser -h /home/appuser appuser \
    && install -d -o appuser -g appuser /app/backend/logs

WORKDIR /app/backend

COPY --from=buildtime --chown=appuser:appuser /opt/venv /opt/venv
COPY --from=buildtime --chown=appuser:appuser /app/backend/ /app/backend/
COPY --from=buildtime --chown=appuser:appuser /app/frontend/ /app/frontend/

USER appuser

CMD ["python", "run_more_securely.py"]

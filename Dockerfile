FROM quay.io/astronomer/astro-runtime:12.6.0

USER root

# Install dbt-snowflake first to cache the heavy layer. It is better than keeping it in requirements.txt because this can be cached now
RUN pip uninstall -y protobuf || true
RUN pip install --no-cache-dir "protobuf>=4.21,<5.0" "dbt-snowflake==1.8.0" "dbt-core==1.8.0"

# Then continue with normal dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

USER astro
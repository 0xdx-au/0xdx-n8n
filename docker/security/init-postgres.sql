-- Create Grafana database and user
CREATE DATABASE grafana;
CREATE USER grafana_user WITH ENCRYPTED PASSWORD 'grafana_secure_password_2024';
GRANT ALL PRIVILEGES ON DATABASE grafana TO grafana_user;

-- Grant connection permissions
GRANT CONNECT ON DATABASE grafana TO grafana_user;
GRANT USAGE ON SCHEMA public TO grafana_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO grafana_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO grafana_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO grafana_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO grafana_user;

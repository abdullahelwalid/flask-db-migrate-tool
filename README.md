# flask-migrate-tool
This tool helps in data migration between multiple environments, it manages the migration file in AWS S3 making your life easier by migrating on the same repo.

# Database Migration Script

This Bash script automates database migrations between development and production environments using Flask and AWS S3.

## Usage

### Prerequisites
- Please make sure you have AWS CLI configured with appropriate permissions.
- Make sure Flask is set up correctly with the necessary database configurations.

### Script Invocation
```bash
./migrate.bash -e <environment> -m <migration_message>

#!/bin/bash

display_usage() {
    echo "Usage: $0 -e <value>"
	echo "Usage: $0 -m <value>"
    exit 1
}

migration_folder_error() {
	echo "!!! migration directory not found !!!"
	exit 1
}

aws_s3_bucket_error(){
	echo "!!! An error has occured while syncing environment !!!"
	exit 1
}

flask_db_migrate_error(){
	echo "!!! An error has occurred while executing "flask db migrate" !!!"
	exit 1
}

flask_db_upgrade_error(){
	echo "!!! An error has occurred while executing "flask db upgrade" !!!"
	exit 1
}

# Check if no arguments are provided
if [ $# -eq 0 ]; then
    echo "Error: No arguments provided."
    display_usage
fi

# Parse flags and their arguments
while getopts ":e:m:" opt; do
    case ${opt} in
        e )
            flag_e="$OPTARG"
            ;;
		m )
			flag_m="$OPTARG"
			;;
        \? )
            echo "Error: Invalid option -$OPTARG" 1>&2
            display_usage
            ;;
        : )
            echo "Error: Option -$OPTARG requires an argument." 1>&2
            display_usage
            ;;
    esac
done

# Check if flag -e is provided
if [ -z "$flag_e" ]; then
    echo "Error: Flag -e with a value is required."
    display_usage
fi

# Check if flag -f is provided
if [ -z "$flag_m" ]; then
    echo "Error: Flag -m with a value is required."	
	display_usage
fi

# Check if the value is either 'dev' or 'prod'
if [ "$flag_e" != "dev" ] && [ "$flag_e" != "prod" ]; then
    echo "Error: Invalid value for -e. It should be either 'dev' or 'prod'."
    display_usage
fi

if [[ ! -d "migrations" ]]; then
    # File does not exist
	mkdir migrations || migration_folder_error
fi

echo "*** Fetching Existing Migrations"
if [ "$flag_e" == "prod" ]; then
	echo "*** Pulling prod ***"
	aws s3 cp s3://{BUCKET_NAME}/production/ migrations --recursive --region me-south-1 || aws_s3_bucket_error
	flask db migrate -m "$flag_m" || flask_db_migrate_error
	flask db upgrade || flask_db_upgrade_error
	aws s3 sync migrations/ s3://{BUCKET_NAME}/production/ --region me-south-1 || aws_s3_bucket_error
	rm -r migrations

elif [ "$flag_e" == "dev" ]; then
	echo "*** Pulling dev ***"
	aws s3 cp s3://{BUCKET_NAME}/development/ migrations --recursive --region me-south-1 || aws_s3_bucket_error
	flask db migrate -m "$flag_m" || flask_db_migrate_error
	flask db upgrade || flask_db_upgrade_error
	aws s3 sync migrations/ s3://{BUCKET_NAME}/development/ --region me-south-1	|| aws_s3_bucket_error
	rm -r migrations
else
	echo "Error while syncing environment: environment not supported"
	exit 1
fi
echo "*** Migration Completed Done ***"

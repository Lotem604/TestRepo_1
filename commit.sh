#!/bin/bash

# Check if enough arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <TaskID> <Appended Message> [Repository Path]"
    exit 1
fi

# Variables
TASKID=$1
APPENDED_MESSAGE=$2
EXCEL_FILE="tasks.xlsx"
CSV_FILE="tasks.csv"

# Check if the Excel file exists
if [ ! -f "$EXCEL_FILE" ]; then
    echo "Error: $EXCEL_FILE not found."
    exit 1
fi

# Convert Excel to CSV
xlsx2csv "$EXCEL_FILE" "$CSV_FILE"

# Find the task row using awk
TASK_ROW=$(awk -F',' -v task_id="$TASKID" '$1 == task_id {print $0}' "$CSV_FILE")

if [ -z "$TASK_ROW" ]; then
    echo "Error: Task ID $TASKID not found in $CSV_FILE."
    exit 1
fi

# Extract fields from the task row
TASK_DESC=$(echo "$TASK_ROW" | awk -F',' '{print $2}')
BRANCH_NAME=$(echo "$TASK_ROW" | awk -F',' '{print $3}')
DEV_NAME=$(echo "$TASK_ROW" | awk -F',' '{print $4}')
GITHUB_URL=$(echo "$TASK_ROW" | awk -F',' '{print $5}')

# Check the current Git branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]; then
    echo "Error: Expected branch $BRANCH_NAME but currently on $CURRENT_BRANCH."
    exit 1
fi

# Create the commit message
CURRENT_DATE_TIME=$(date '+%Y-%m-%d %H:%M:%S')
COMMIT_MESSAGE="$TASKID - $CURRENT_DATE_TIME - $BRANCH_NAME - $DEV_NAME - $TASK_DESC - $APPENDED_MESSAGE"

# Handle optional repository path
if [ "$#" -eq 3 ]; then
    REPO_PATH=$3
    cd "$REPO_PATH" || { echo "Error: Repository path $REPO_PATH not found."; exit 1; }
fi

# Perform the Git operations
git add .
git commit -m "$COMMIT_MESSAGE"

# Ask if the user wants to push changes
read -p "Do you want to push the changes to GitHub? (y/n): " PUSH_CONFIRMATION
if [ "$PUSH_CONFIRMATION" = "y" ]; then
    git push
fi

# Return to the original directory if changed
if [ "$#" -eq 3 ]; then
    cd - || exit
fi

echo "Commit completed successfully!"
#!/usr/bin/env bash
#
# A shortcut to start the local development server and preview the site.

# Check if Bundler is installed
if ! command -v bundle &> /dev/null; then
    echo "Error: Bundler is not installed. Please install Ruby and Bundler first."
    exit 1
fi

# Ensure dependencies are installed
echo "> Checking dependencies..."
bundle install

# Start the Jekyll server using the existing tools/run.sh
echo "> Starting local preview..."
bash tools/run.sh

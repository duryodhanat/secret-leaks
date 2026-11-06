"""
Sample Python Service: Main Entry Point
Demonstrates best practice secret handling using environment variables.
"""
import os
import sys

def get_database_url() -> str:
    """Retrieve database URL securely from environment."""
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        print("DATABASE_URL is not set. Using local development default.")
        return "postgresql://localhost:5432/devdb"
    return db_url

def main():
    print("Starting sample Python service...")
    db_url = get_database_url()
    print(f"Connected to database endpoint: {db_url.split('@')[-1] if '@' in db_url else db_url}")
    print("Service initialized successfully without hardcoded secrets.")

if __name__ == "__main__":
    main()

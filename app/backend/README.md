# Backend Setup

This document provides instructions to set up the Python virtual environment for the backend application.

## Prerequisites

- Python 3.x installed on your system.
- `pip` (Python package installer) available.

## Setup Instructions

1.  **Navigate to the backend directory:**
    ```bash
    cd app/backend
    ```

2.  **Create a Python virtual environment:**
    It is recommended to use a virtual environment to manage project dependencies. You can name it `new_myenv` (as used in the project) or any other name you prefer.
    ```bash
    python3 -m venv new_myenv
    ```
    If you choose a different name, make sure to update the `.gitignore` file accordingly if you haven't used a generic pattern like `venv/` or `myenv/`.

3.  **Activate the virtual environment:**

    -   On macOS and Linux:
        ```bash
        source new_myenv/bin/activate
        ```
    -   On Windows:
        ```bash
        .\new_myenv\Scripts\activate
        ```

4.  **Install the required packages:**
    All dependencies are listed in the `requirements.txt` file.
    ```bash
    pip install -r requirements.txt
    ```

5.  **Deactivate the virtual environment (when done):**
    When you are finished working on the project, you can deactivate the virtual environment:
    ```bash
    deactivate
    ```

## Running the Backend

(Add instructions here on how to run your backend server, e.g., `python main.py` or `gunicorn main:app`) 
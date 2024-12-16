FROM nvcr.io/nvidia/modulus/modulus:24.12

# Install mlflow
RUN pip install --no-cache-dir mlflow

# Copy additional scripts and directories
COPY utils.py utils.py
COPY surface/ surface/
COPY volume/ volume/

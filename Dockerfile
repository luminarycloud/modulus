FROM nvcr.io/nvidia/modulus/modulus:24.12
# Install mlflow
RUN pip install --no-cache-dir mlflow torchinfo
# Copy additional scripts and directories
COPY modulus/ modulus/ 
COPY examples/ examples/
ENV PYTHONPATH=/workspace

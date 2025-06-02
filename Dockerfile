ARG python_image_tag=3.13-slim

# -- COMPILER IMAGE

FROM python:${python_image_tag} as compiler-image

# -- Layer: OS

RUN apt-get update -y && \
    pip3 install --upgrade pip

# -- Layer: Python

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY ./requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# -- BUILDER IMAGE

FROM python:${python_image_tag} as builder-image

# -- Layer: OS

RUN apt-get update -y && \
    apt-get install -y procps && \
    rm -rf /var/lib/apt/lists/*

# -- Layer: Python

COPY --from=compiler-image /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

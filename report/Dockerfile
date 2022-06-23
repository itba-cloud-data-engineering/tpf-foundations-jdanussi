FROM python:3.10.4-slim

# Run updates and install pip upgrade
RUN apt-get update && apt-get upgrade -y
RUN python -m pip install --upgrade pip

# Set up of working directory
WORKDIR /report/

# Install python dependencies
COPY requirements.txt . 
RUN pip install -r requirements.txt

# Create directories a copy files
RUN mkdir -p /report/config
COPY /config/* /report/config/

RUN mkdir -p /report/output

RUN mkdir -p /report/sql
COPY report.py .

# Set up the container startup command 
CMD [ "python3", "report.py" ]
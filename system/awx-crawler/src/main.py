#!/usr/bin/python3
import requests
import re
import os
import logging
import sys
import sqlite3
from functools import wraps
import time
import datetime
import json

LOGLEVEL = os.environ.get('LOGLEVEL', 'INFO').upper()
logging.basicConfig(stream=sys.stdout, level=LOGLEVEL)
log = logging.getLogger()


ELASTIC_BASIC_AUTH = requests.auth.HTTPBasicAuth(os.getenv("ELASTIC_USER"), os.getenv("ELASTIC_PASS"))
ENVIRONMENT = os.getenv("ELASTIC_ENV")
AWX_BASE_URL = os.getenv("AWX_URL")
AWX_TOKEN = os.getenv("AWX_TOKEN")
CHECKPOINT_JOBS = f"/mnt/checkpoints/{ENVIRONMENT}/job"
CHECKPOINT_WORKFLOW = f"/mnt/checkpoints/{ENVIRONMENT}/workflow"
ES_URL = os.getenv("ELASTIC_URL")
ES_INDEX = os.getenv("ELASTIC_INDEX")
TIMEFORMAT = "%Y-%m-%dT%H:%M:%S.%fZ"

def timeit(func):
    """Decorator to time function execution."""
    @wraps(func)
    def timeit_wrapper(*args, **kwargs):
        start_time = time.perf_counter()
        result = func(*args, **kwargs)
        end_time = time.perf_counter()
        total_time = end_time - start_time
        log.info(f'Function {func.__name__}{args} {kwargs} took {total_time:.4f} seconds')
        return result
    return timeit_wrapper

def write_checkpoint(file, value):
    """Write the checkpoint value to a file."""
    try:
        with open(file, "w") as f:
            f.write(value)
        log.info(f"Checkpoint <{value}> written to {file}")
    except Exception as e:
        log.error(f"Failed to write checkpoint to {file}: {e}")

def get_checkpoint(file):
    """Read the checkpoint value from a file."""
    try:
        with open(file, "r") as f:
            checkpoint = f.read().strip()
        return checkpoint
    except Exception as e:
        log.warning(f"Failed to read checkpoint from {file}: {e}")
        # Return a default date if no checkpoint is found
        return "2024-01-01T00:00:00.000000Z"

def connection_check():
    """Check if the connection to AWX is successful."""
    try:
        response = requests.get(url=f"{AWX_BASE_URL}/api/v2")
        response.raise_for_status()
        log.info("Connection to AWX successful.")
    except requests.RequestException as e:
        log.error(f"Failed to connect to AWX: {e}")
        exit(1)

def credential_check():
    """Check if the credentials for AWX are valid."""
    try:
        headers = {
            "Authorization": f"Bearer {AWX_TOKEN}"
        }
        endpoint = "/jobs"
        response = requests.get(url=f"{AWX_BASE_URL}/api/v2/{endpoint}", headers=headers)
        response.raise_for_status()
        log.info("Authentication to AWX successful.")
    except requests.RequestException as e:
        log.error(f"Failed to authenticate with AWX: {e}")
        exit(1)

# Checking Connection and Credentials
connection_check()
credential_check()

def push_filedata_to_elastic(file):
    """Push data from a file to Elasticsearch."""
    bulk_url = f"{ES_URL}/{ES_INDEX}/_bulk"
    try:
        with open(file, "rb") as f:
            bulk_data = f.read()
        
        headers = {
            "Content-Type": "application/x-ndjson",
            "Authorization": f"Bearer {AWX_TOKEN}"
        }
        response = requests.post(bulk_url, headers=headers, data=bulk_data, auth=ELASTIC_BASIC_AUTH)
        
        if response.status_code == 200:
            log.info("Bulk request to Elasticsearch successful.")
        else:
            log.error(f"Bulk request failed: {response.json()}")
    except Exception as e:
        log.error(f"Failed to push data to Elasticsearch: {e}")
        exit(1)

def write_data_to_json(file, data):
    """Write data to a JSON file in Elasticsearch bulk format."""
    try:
        json_in = ""
        with open(file, "w") as f:
            for entry in data:
                json_in += f"""{{ "index" : {{ "_index" : "{ES_INDEX}" }} }}
{json.dumps(entry)}
"""
            f.write(json_in)
        log.info(f"Data written to {file}")
    except Exception as e:
        log.error(f"Failed to write data to JSON file {file}: {e}")
        exit(1)

def get_stdout(url):
    """Fetch the stdout of a job."""
    try:
        headers = {
            "Authorization": f"Bearer {AWX_TOKEN}"
        }
        response = requests.get(url=url, headers=headers, params={"format": "txt"})
        index=response.text.find("FAILED")
        return response.text[:index]
    except Exception as e:
        log.error(f"Failed to fetch stdout from {url}: {e}")
        return ""

@timeit
def populate_wf_data():
    """Populate workflow job data from AWX and push to Elasticsearch."""
    endpoint = "/workflow_jobs"
    latest_id = get_checkpoint(CHECKPOINT_WORKFLOW)
    log.info(f"Running request with checkpoint of: {latest_id}")
    iterations = 1
    job_count = 1
    params = {"order_by": "finished", "finished__gt": latest_id, "page_size": "200"}
    url = f"{AWX_BASE_URL}/api/v2/{endpoint}"
    headers = {
        "Authorization": f"Bearer {AWX_TOKEN}"
    }

    while True:
        data = []
        try:
            response = requests.get(url=url, headers=headers, params=params)
            response.raise_for_status()
            response_data = response.json()
        except requests.RequestException as e:
            log.error(f"Failed to fetch workflow data: {e}")
            break
        
        entries = response_data.get("results", [])

        for entry in entries:
            data.append({
                "id": entry.get("id"),
                "name": entry.get("name"),
                "status": entry.get("status"),
                "finished": entry.get("finished"),
                "launch_type": entry.get("launch_type"),
                "controller_node": entry.get("controller_node"),
                "launched_by": entry.get("launched_by"),
                "extra_vars": entry.get("extra_vars"),
                "endpoint": endpoint,
                "@timestamp": entry.get("created")
            })
        
        if data:
            log.info(f"Fetched page {iterations} ({job_count}/{job_count + len(data)}) of workflow job data")
            write_data_to_json(file="/tmp/awx-workflow.json", data=data)
            push_filedata_to_elastic(file="/tmp/awx-workflow.json")
            new_checkpoint = response_data.get("results")[-1].get("finished")
            write_checkpoint(file=CHECKPOINT_WORKFLOW, value=new_checkpoint)
        
        job_count += len(data) + 1
        iterations += 1
        
        if not response_data.get("next"):
            log.info("Workflow data is up-to-date.")
            break
        
        url = f"{AWX_BASE_URL}{response_data.get('next')}"

    if not data:
        log.info("No new workflow data found.")
        exit(0)

@timeit
def populate_job_data():
    """Populate job data from AWX and push to Elasticsearch."""
    endpoint = "/jobs"
    latest_id = get_checkpoint(CHECKPOINT_JOBS)
    log.info(f"Running request with checkpoint of: {latest_id}")
    iterations = 1
    job_count = 1
    params = {"order_by": "finished", "finished__gt": latest_id, "page_size": "200"}
    url = f"{AWX_BASE_URL}/api/v2/{endpoint}"
    headers = {
        "Authorization": f"Bearer {AWX_TOKEN}"
    }
    while True:
        data = []

        try:
            response = requests.get(url=url, headers=headers, params=params)
            response.raise_for_status()
            response_data = response.json()
        except requests.RequestException as e:
            log.error(f"Failed to fetch job data: {e}")
            break
        
        entries = response_data.get("results", [])

        for entry in entries:
            stderr = None
            if entry.get("status") == "failed":
                stderr = entry.get("related").get("stdout")
            
            wf_triggered = entry.get("launch_type") == "workflow"
            wf_info = entry.get("summary_fields", {}).get("source_workflow_job", {})
            
            data.append({
                "id": entry.get("id"),
                "name": entry.get("name"),
                "status": entry.get("status"),
                "finished": entry.get("finished"),
                "launch_type": entry.get("launch_type"),
                "playbook": entry.get("playbook"),
                "controller_node": entry.get("controller_node"),
                "launched_by": entry.get("launched_by"),
                "extra_vars": entry.get("extra_vars"),
                "stderr": stderr,
                "workflow": {
                    "id": wf_info.get("id"),
                    "triggered": wf_triggered,
                    "name": wf_info.get("name"),
                    "status": wf_info.get("status"),
                },
                "endpoint": endpoint,
                "@timestamp": entry.get("finished")
            })
        
        if data:
            log.info(f"Fetched page {iterations} ({job_count}/{job_count + len(data)}) of job data")
            write_data_to_json(file="/tmp/awx-data.json", data=data)
            push_filedata_to_elastic(file="/tmp/awx-data.json")
            new_checkpoint = response_data.get("results")[-1].get("finished")
            write_checkpoint(file=CHECKPOINT_JOBS, value=new_checkpoint)
        
        job_count += len(data) + 1
        iterations += 1
        
        if not response_data.get("next"):
            log.info("Job data is up-to-date.")
            break
        
        url = f"{AWX_BASE_URL}{response_data.get('next')}"

    if not data:
        log.info("No new job data found.")
        exit(0)

# Execute data population functions
populate_job_data()
populate_wf_data()

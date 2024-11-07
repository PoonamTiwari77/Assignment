from fastapi import FastAPI, HTTPException  # Correct import from fastapi
import subprocess
import os
import boto3
from botocore.exceptions import ClientError
from pydantic import BaseModel

app = FastAPI()

# Define the path to your Terraform and Backend directory
TERRAFORM_DIR = os.path.join(os.path.dirname(__file__), "terraform")
BACKEND_DIR = os.path.join(TERRAFORM_DIR, "backend")

AWS_PROFILE = "aws-profile"
REGION = "us-east-1"                     # Change this to your desired region


class PlanRequest(BaseModel):
    instance_type: str
    num_replicas: int

@app.post("/terraform/setup-s3-backend/")
async def setup_s3_backend():
    try:
        # Change directory to where your Terraform configuration is located.
        os.chdir(BACKEND_DIR)

        # Initialize Terraform.
        subprocess.run(["terraform", "init"], check=True)

        # Create a plan.
        subprocess.run(["terraform", "plan"], check=True)

        # Apply Terraform configuration to create resources.
        subprocess.run(["terraform", "apply", "-auto-approve"], check=True)

        return {
            "message": "S3 backend setup successfully."
        }
    except subprocess.CalledProcessError as e:
        raise HTTPException(status_code=500, detail=f"Terraform command failed: {e}")

def update_tfvars(instance_type: str, num_replicas: int):
    tfvars_file_path = os.path.join(TERRAFORM_DIR, "terraform.tfvars")
    
    # Read existing tfvars file or create a new one if it doesn't exist
    if os.path.exists(tfvars_file_path):
        with open(tfvars_file_path, "r") as tfvars_file:
            lines = tfvars_file.readlines()
        
        # Check and update or add instance_type and num_replicas
        updated = False
        for i in range(len(lines)):
            if lines[i].startswith("instance_type"):
                lines[i] = f'instance_type = "{instance_type}"\n'
                updated = True
            elif lines[i].startswith("num_replicas"):
                lines[i] = f'num_replicas = {num_replicas}\n'
                updated = True
        
        # If not updated, append new values
        if not updated:
            lines.append(f'instance_type = "{instance_type}"\n')
            lines.append(f'num_replicas = {num_replicas}\n')
        
        # Write back to tfvars file
        with open(tfvars_file_path, "w") as tfvars_file:
            tfvars_file.writelines(lines)
    else:
        # Create a new tfvars file with the provided variables
        with open(tfvars_file_path, "w") as tfvars_file:
            tfvars_file.write(f'instance_type = "{instance_type}"\n')
            tfvars_file.write(f'num_replicas = {num_replicas}\n')

@app.post("/terraform/init/")
async def terraform_init():
    try:
        # Create the S3 bucket before initializing Terraform

        os.chdir(TERRAFORM_DIR)
        subprocess.run(["terraform", "init"], check=True)
        return {"message": "Terraform initialized successfully."}
    except subprocess.CalledProcessError as e:
        raise HTTPException(status_code=500, detail=f"Terraform init failed: {e}")

@app.post("/terraform/plan/")
async def terraform_plan(request: PlanRequest):
    try:
        # Update the terraform.tfvars file with instance type and replica count
        update_tfvars(request.instance_type, request.num_replicas)

        os.chdir(TERRAFORM_DIR)
        subprocess.run(["terraform", "plan"], check=True)
        return {"message": "Terraform plan executed successfully."}
    except subprocess.CalledProcessError as e:
        raise HTTPException(status_code=500, detail=f"Terraform plan failed: {e}")

@app.post("/terraform/apply/")
async def terraform_apply():
    try:
        os.chdir(TERRAFORM_DIR)
        subprocess.run(["terraform", "apply", "-auto-approve"], check=True)
        return {"message": "Terraform apply executed successfully."}
    except subprocess.CalledProcessError as e:
        raise HTTPException(status_code=500, detail=f"Terraform apply failed: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)






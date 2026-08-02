#!/usr/bin/env python
# ==============================================================================
# Author: Prakriti Mandal
# Contact: prakritimandal611@gmail.com
# ==============================================================================
import os
import sys
import json
from pathlib import Path

# Configure Django inline
from django.conf import settings
import django

if not settings.configured:
    settings.configure(
        INSTALLED_APPS=[
            'django.contrib.contenttypes',
            'django.contrib.auth',
            'rest_framework',
        ],
        DATABASES={
            'default': {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': ':memory:',
            }
        }
    )
    django.setup()

from django.db import models
from django.core.validators import MinLengthValidator, MinValueValidator, MaxValueValidator, EmailValidator
from rest_framework import serializers

class Student(models.Model):
    student_id = models.CharField(
        max_length=10,
        validators=[MinLengthValidator(3)],
        primary_key=True
    )
    name = models.CharField(
        max_length=100,
        validators=[MinLengthValidator(2)]
    )
    age = models.IntegerField(
        validators=[MinValueValidator(5), MaxValueValidator(100)]
    )
    email = models.EmailField(
        validators=[EmailValidator()]
    )
    GRADE_CHOICES = [
        ('A', 'A'),
        ('B', 'B'),
        ('C', 'C'),
        ('D', 'D'),
        ('F', 'F'),
    ]
    grade = models.CharField(
        max_length=1,
        choices=GRADE_CHOICES
    )
    courses = models.JSONField()

    class Meta:
        app_label = 'auth'  # Using 'auth' since it is already in INSTALLED_APPS

class StudentSerializer(serializers.ModelSerializer):
    # Override student_id to prevent UniqueValidator database queries
    student_id = serializers.CharField(
        max_length=10,
        validators=[MinLengthValidator(3)]
    )

    class Meta:
        model = Student
        fields = ['student_id', 'name', 'age', 'email', 'grade', 'courses']

    def validate_courses(self, value):
        if not isinstance(value, list) or len(value) < 1:
            raise serializers.ValidationError("courses must be a list with at least one course.")
        for item in value:
            if not isinstance(item, str) or not item.strip():
                raise serializers.ValidationError("Each course must be a non-empty string.")
        return value
      
def validate_json(file_path: str) -> dict:
    path = Path(file_path)
    if not path.exists():
        return {"status": "error", "message": f"File not found: {file_path}"}
    
    try:
        with open(path, "r", encoding="utf-8") as file:
            data = json.load(file)
    except json.JSONDecodeError as e:
        return {"status": "error", "message": f"Invalid JSON syntax: {str(e)}"}
    except Exception as e:
        return {"status": "error", "message": f"Failed to read file: {str(e)}"}

    records = data if isinstance(data, list) else [data]
    results = {
        "status": "success",
        "total_records": len(records),
        "valid_count": 0,
        "invalid_count": 0,
        "details": []
    }

    expected_fields = ["student_id", "name", "age", "email", "grade", "courses"]

    for index, record in enumerate(records):
        serializer = StudentSerializer(data=record)
        is_valid = serializer.is_valid()
        errors = serializer.errors
        
        dcyn_lib = {}
        for field in expected_fields:
            if field in errors:
                dcyn_lib[field] = "No"
            else:
                dcyn_lib[field] = "Yes"

        if is_valid:
            results["valid_count"] += 1
            results["details"].append({
                "record_index": index,
                "valid": True,
                "data": serializer.validated_data,
                "dcyn_library": dcyn_lib
            })
        else:
            results["invalid_count"] += 1
            results["details"].append({
                "record_index": index,
                "valid": False,
                "errors": errors,
                "dcyn_library": dcyn_lib
            })

    return results

def main():
    if len(sys.argv) < 2:
        print("Usage: python serialiser.py <file_or_directory>")
        sys.exit(1)
        
    input_path = Path(sys.argv[1])
    
    if not input_path.exists():
        print(f"Error: Path {input_path} does not exist.")
        sys.exit(1)
        
    json_files = []
    if input_path.is_dir():
        json_files = sorted(list(input_path.glob("*.json")))
        if not json_files:
            print(f"No .json files found in directory {input_path}.")
            sys.exit(0)
    else:
        if not input_path.name.endswith(".json"):
            print("Error: Input file must end with .json")
            sys.exit(1)
        json_files = [input_path]
        
    overall_failed = False
    
    for json_file in json_files:
        print(f"\nValidating file: {json_file}")    
        res = validate_json(str(json_file))
        
        # Output the validation results in a pretty-printed JSON format
        print(json.dumps(res, indent=2))
        
        # Check validation failures
        if res.get("status") != "success" or res.get("invalid_count", 0) > 0:
            print(f"Schema mismatch/validation failed for: {json_file}")
            overall_failed = True
            
    if overall_failed:
        print("\nOne or more datasets failed schema validation. Aborting execution.")
        sys.exit(1)
    else:
        print("\nAll datasets validated successfully.")

if __name__ == "__main__":
    main()

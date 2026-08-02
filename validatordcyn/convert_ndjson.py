# ==============================================================================
# Author: Prakriti Mandal
# Contact: prakritimandal611@gmail.com
# ==============================================================================
import sys
import json
from pathlib import Path

def main():
    if len(sys.argv) < 3:
        print("Usage: python convert_ndjson.py <input_file.json> <output_file.ndjson>")
        sys.exit(1)
        
    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    
    if not input_path.exists():
        print(f"Error: Input file {input_path} not found.")
        sys.exit(1)
        
    try:
        with open(input_path, "r", encoding="utf-8") as infile:
            data = json.load(infile)
            
        records = data if isinstance(data, list) else [data]
        
        with open(output_path, "w", encoding="utf-8") as outfile:
            for record in records:
                outfile.write(json.dumps(record) + "\n")
                
        print(f"Successfully converted {input_path} to {output_path} (NDJSON format).")
    except Exception as e:
        print(f"Failed to convert file: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()

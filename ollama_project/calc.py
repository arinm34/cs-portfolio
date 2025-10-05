#!/usr/bin/env python3
import sys

def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} add <num1> <num2>")
        sys.exit(1)
    
    operation = sys.argv[1]
    
    try:
        num1 = float(sys.argv[2])
        num2 = float(sys.argv[3])
    except ValueError:
        print("Error: Both arguments must be numbers")
        sys.exit(1)
    
    if operation == "add":
        result = num1 + num2
    elif operation == "sub":
        result = num1 - num2
    elif operation == "mul":
        result = num1 * num2
    elif operation == "div":
        result = num1 / num2
    else:
        print(f"Error: Unknown operation '{operation}'")
        print("Supported operations: add, sub, mul, div")
        sys.exit(1)
    
    # Print integer if result is whole number, otherwise float
    if result == int(result):
        print(int(result))
    else:
        print(result)

if __name__ == "__main__":
    main()
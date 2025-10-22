#!/usr/bin/env python3
"""
Python Boilerplate - Essential Syntax Reference
"""

# Importing libraries
import os
import sys
from datetime import datetime
from typing import List, Dict, Optional

# Constants
APP_NAME = "Python Boilerplate"
VERSION = "1.0.0"


# Classes
class Person:
    """Example class definition"""

    def __init__(self, name: str, age: int):
        self.name = name
        self.age = age

    def greet(self) -> str:
        return f"Hello, my name is {self.name} and I'm {self.age} years old."

    def is_adult(self) -> bool:
        return self.age >= 18


# Functions
def add_numbers(a: int, b: int) -> int:
    """Simple function that adds two numbers"""
    return a + b


def process_list(items: List[int]) -> Dict[str, any]:
    """Function demonstrating list operations"""
    if not items:
        return {"sum": 0, "average": 0, "max": None, "min": None}

    return {
        "sum": sum(items),
        "average": sum(items) / len(items),
        "max": max(items),
        "min": min(items)
    }


def demonstrate_conditionals(value: int) -> str:
    """Conditional statements examples"""

    # If-elif-else
    if value > 0:
        result = "positive"
    elif value < 0:
        result = "negative"
    else:
        result = "zero"

    # Ternary operator
    parity = "even" if value % 2 == 0 else "odd"

    return f"{value} is {result} and {parity}"


def demonstrate_loops():
    """Loop examples"""

    print("\n=== For Loop ===")
    # For loop with range
    for i in range(5):
        print(f"Count: {i}")

    print("\n=== For Loop with List ===")
    # For loop with list
    fruits = ["apple", "banana", "cherry"]
    for fruit in fruits:
        print(f"Fruit: {fruit}")

    print("\n=== For Loop with Enumerate ===")
    # For loop with enumerate
    for index, fruit in enumerate(fruits):
        print(f"{index}: {fruit}")

    print("\n=== While Loop ===")
    # While loop
    count = 0
    while count < 3:
        print(f"While count: {count}")
        count += 1

    print("\n=== List Comprehension ===")
    # List comprehension
    squares = [x**2 for x in range(5)]
    print(f"Squares: {squares}")

    # List comprehension with condition
    even_squares = [x**2 for x in range(10) if x % 2 == 0]
    print(f"Even squares: {even_squares}")


def demonstrate_data_structures():
    """Common data structures"""

    print("\n=== Lists ===")
    my_list = [1, 2, 3, 4, 5]
    my_list.append(6)
    my_list.extend([7, 8])
    print(f"List: {my_list}")

    print("\n=== Dictionaries ===")
    my_dict = {
        "name": "John",
        "age": 30,
        "city": "New York"
    }
    my_dict["country"] = "USA"
    print(f"Dictionary: {my_dict}")

    # Dictionary iteration
    for key, value in my_dict.items():
        print(f"  {key}: {value}")

    print("\n=== Sets ===")
    my_set = {1, 2, 3, 4, 5}
    my_set.add(6)
    print(f"Set: {my_set}")

    print("\n=== Tuples ===")
    my_tuple = (1, 2, 3)
    print(f"Tuple: {my_tuple}")


def demonstrate_error_handling():
    """Error handling examples"""

    print("\n=== Error Handling ===")

    # Try-except
    try:
        result = 10 / 2
        print(f"Division result: {result}")
    except ZeroDivisionError as e:
        print(f"Error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")
    finally:
        print("Finally block executed")

    # Try-except with else
    try:
        value = int("123")
    except ValueError:
        print("Invalid number")
    else:
        print(f"Successfully parsed: {value}")


def demonstrate_file_operations():
    """File I/O examples"""

    print("\n=== File Operations ===")

    filename = "temp_example.txt"

    # Writing to file
    with open(filename, 'w') as f:
        f.write("Hello, World!\n")
        f.write("This is a test file.\n")

    # Reading from file
    with open(filename, 'r') as f:
        content = f.read()
        print(f"File content:\n{content}")

    # Reading line by line
    with open(filename, 'r') as f:
        for line in f:
            print(f"Line: {line.strip()}")

    # Clean up
    if os.path.exists(filename):
        os.remove(filename)
        print(f"Removed {filename}")


def main():
    """Main function"""

    print(f"=== {APP_NAME} v{VERSION} ===")
    print(f"Started at: {datetime.now()}\n")

    # Using a class
    person = Person("Alice", 25)
    print(person.greet())
    print(f"Is adult? {person.is_adult()}\n")

    # Using functions
    print(f"Add 5 + 3 = {add_numbers(5, 3)}")

    numbers = [1, 2, 3, 4, 5]
    stats = process_list(numbers)
    print(f"\nList stats: {stats}")

    # Conditionals
    print(f"\n{demonstrate_conditionals(10)}")
    print(demonstrate_conditionals(-5))
    print(demonstrate_conditionals(0))

    # Loops
    demonstrate_loops()

    # Data structures
    demonstrate_data_structures()

    # Error handling
    demonstrate_error_handling()

    # File operations
    demonstrate_file_operations()

    print(f"\n=== Program completed at: {datetime.now()} ===")


if __name__ == "__main__":
    main()

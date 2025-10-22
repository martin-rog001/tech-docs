# Python Cheatsheet

## Essential Features

### Variables and Data Types

**Basic Data Types**
```python
# Integer
x = 10
y = -5

# Float
price = 19.99
pi = 3.14159

# String
name = "John"
message = 'Hello World'
multiline = """This is a
multi-line string"""

# Boolean
is_active = True
is_deleted = False

# None
result = None
```

**Type Checking and Conversion**
```python
# Type checking
type(10)           # <class 'int'>
isinstance(10, int)  # True

# Type conversion
int("123")         # 123
float("3.14")      # 3.14
str(123)           # "123"
bool(1)            # True
list("abc")        # ['a', 'b', 'c']
```

### String Operations

**String Formatting**
```python
# f-strings (Python 3.6+)
name = "Alice"
age = 30
message = f"My name is {name} and I'm {age} years old"
formatted = f"{price:.2f}"  # 19.99

# format() method
message = "Hello, {}!".format(name)
message = "Hello, {name}!".format(name="Bob")

# % formatting (old style)
message = "Hello, %s!" % name
message = "Number: %d, Float: %.2f" % (10, 3.14)
```

**String Methods**
```python
text = "Hello World"

# Case conversion
text.upper()           # "HELLO WORLD"
text.lower()           # "hello world"
text.capitalize()      # "Hello world"
text.title()           # "Hello World"

# Searching
text.find("World")     # 6
text.index("World")    # 6 (raises ValueError if not found)
text.count("l")        # 3
text.startswith("He")  # True
text.endswith("ld")    # True

# Modification
text.replace("World", "Python")  # "Hello Python"
text.strip()           # Remove whitespace from both ends
text.lstrip()          # Remove from left
text.rstrip()          # Remove from right

# Splitting and joining
text.split()           # ["Hello", "World"]
"-".join(["a", "b"])   # "a-b"

# Checking
text.isalpha()         # False (contains space)
text.isdigit()         # False
text.isalnum()         # False
```

**String Slicing**
```python
text = "Hello World"

text[0]        # "H"
text[-1]       # "d"
text[0:5]      # "Hello"
text[:5]       # "Hello"
text[6:]       # "World"
text[::2]      # "HloWrd" (every 2nd character)
text[::-1]     # "dlroW olleH" (reverse)
```

### Lists

**Creating and Accessing Lists**
```python
# Creating lists
numbers = [1, 2, 3, 4, 5]
mixed = [1, "two", 3.0, True]
nested = [[1, 2], [3, 4]]
empty = []
range_list = list(range(5))  # [0, 1, 2, 3, 4]

# Accessing elements
numbers[0]      # 1
numbers[-1]     # 5
numbers[1:3]    # [2, 3]
```

**List Methods**
```python
numbers = [1, 2, 3]

# Adding elements
numbers.append(4)          # [1, 2, 3, 4]
numbers.extend([5, 6])     # [1, 2, 3, 4, 5, 6]
numbers.insert(0, 0)       # [0, 1, 2, 3, 4, 5, 6]

# Removing elements
numbers.remove(3)          # Remove first occurrence of 3
popped = numbers.pop()     # Remove and return last element
popped = numbers.pop(0)    # Remove and return element at index
numbers.clear()            # Remove all elements

# Other operations
numbers = [3, 1, 4, 1, 5]
numbers.sort()             # Sort in place
numbers.reverse()          # Reverse in place
numbers.count(1)           # Count occurrences
numbers.index(4)           # Find index of first occurrence
```

**List Comprehensions**
```python
# Basic list comprehension
squares = [x**2 for x in range(10)]

# With condition
evens = [x for x in range(10) if x % 2 == 0]

# With if-else
labels = ["even" if x % 2 == 0 else "odd" for x in range(5)]

# Nested comprehension
matrix = [[i*j for j in range(3)] for i in range(3)]

# Flattening
nested = [[1, 2], [3, 4], [5, 6]]
flat = [item for sublist in nested for item in sublist]
```

### Tuples

**Creating and Using Tuples**
```python
# Creating tuples
point = (10, 20)
single = (1,)          # Note the comma
empty = ()
coordinates = 10, 20   # Parentheses optional

# Accessing elements
point[0]               # 10
x, y = point           # Unpacking

# Tuples are immutable
# point[0] = 15        # TypeError

# Named tuples
from collections import namedtuple
Point = namedtuple('Point', ['x', 'y'])
p = Point(10, 20)
p.x                    # 10
```

### Dictionaries

**Creating and Accessing Dictionaries**
```python
# Creating dictionaries
person = {"name": "John", "age": 30}
person = dict(name="John", age=30)
empty = {}

# Accessing values
person["name"]         # "John"
person.get("name")     # "John"
person.get("city", "Unknown")  # Return default if key not found

# Adding/updating
person["city"] = "NYC"
person.update({"country": "USA", "age": 31})
```

**Dictionary Methods**
```python
person = {"name": "John", "age": 30, "city": "NYC"}

# Keys, values, items
person.keys()          # dict_keys(['name', 'age', 'city'])
person.values()        # dict_values(['John', 30, 'NYC'])
person.items()         # dict_items([('name', 'John'), ...])

# Removing
person.pop("city")     # Remove and return value
person.popitem()       # Remove and return last (key, value)
del person["age"]      # Delete key
person.clear()         # Remove all items

# Checking
"name" in person       # True
"email" not in person  # True

# Merging (Python 3.9+)
dict1 = {"a": 1}
dict2 = {"b": 2}
merged = dict1 | dict2  # {"a": 1, "b": 2}
```

**Dictionary Comprehensions**
```python
# Basic dict comprehension
squares = {x: x**2 for x in range(5)}

# With condition
evens = {x: x**2 for x in range(10) if x % 2 == 0}

# From two lists
keys = ["a", "b", "c"]
values = [1, 2, 3]
d = {k: v for k, v in zip(keys, values)}

# Swap keys and values
original = {"a": 1, "b": 2}
swapped = {v: k for k, v in original.items()}
```

### Sets

**Creating and Using Sets**
```python
# Creating sets
numbers = {1, 2, 3, 4, 5}
empty = set()          # {} creates empty dict, not set
from_list = set([1, 2, 2, 3])  # {1, 2, 3} - duplicates removed

# Adding/removing
numbers.add(6)
numbers.update([7, 8, 9])
numbers.remove(5)      # Raises KeyError if not found
numbers.discard(5)     # No error if not found
numbers.pop()          # Remove and return arbitrary element
numbers.clear()
```

**Set Operations**
```python
a = {1, 2, 3, 4}
b = {3, 4, 5, 6}

# Union
a | b                  # {1, 2, 3, 4, 5, 6}
a.union(b)

# Intersection
a & b                  # {3, 4}
a.intersection(b)

# Difference
a - b                  # {1, 2}
a.difference(b)

# Symmetric difference
a ^ b                  # {1, 2, 5, 6}
a.symmetric_difference(b)

# Subset/superset
{1, 2}.issubset(a)     # True
a.issuperset({1, 2})   # True
```

### Control Flow

**If Statements**
```python
# Basic if-else
if x > 0:
    print("Positive")
elif x < 0:
    print("Negative")
else:
    print("Zero")

# Ternary operator
result = "Even" if x % 2 == 0 else "Odd"

# Multiple conditions
if x > 0 and y > 0:
    print("Both positive")

if x > 0 or y > 0:
    print("At least one positive")

if not x:
    print("x is falsy")

# Membership testing
if x in [1, 2, 3]:
    print("Found")

if "key" in dictionary:
    print("Key exists")
```

**For Loops**
```python
# Iterate over list
for item in [1, 2, 3]:
    print(item)

# Iterate with index
for i, item in enumerate([1, 2, 3]):
    print(f"Index {i}: {item}")

# Iterate over range
for i in range(5):          # 0 to 4
    print(i)

for i in range(2, 10, 2):   # 2, 4, 6, 8
    print(i)

# Iterate over dictionary
for key in person:
    print(key, person[key])

for key, value in person.items():
    print(key, value)

# Multiple sequences
for x, y in zip([1, 2, 3], ['a', 'b', 'c']):
    print(x, y)
```

**While Loops**
```python
# Basic while loop
count = 0
while count < 5:
    print(count)
    count += 1

# While with break
while True:
    response = input("Continue? (y/n): ")
    if response == 'n':
        break

# While with continue
i = 0
while i < 10:
    i += 1
    if i % 2 == 0:
        continue
    print(i)  # Only odd numbers

# While-else
i = 0
while i < 5:
    print(i)
    i += 1
else:
    print("Loop completed normally")
```

### Functions

**Defining Functions**
```python
# Basic function
def greet(name):
    return f"Hello, {name}!"

# Multiple parameters
def add(a, b):
    return a + b

# Default parameters
def greet(name, greeting="Hello"):
    return f"{greeting}, {name}!"

# Variable arguments
def sum_all(*args):
    return sum(args)

# Keyword arguments
def create_profile(**kwargs):
    return kwargs

# Mixed parameters
def func(a, b, *args, key="value", **kwargs):
    pass

# Type hints (Python 3.5+)
def add(a: int, b: int) -> int:
    return a + b
```

**Lambda Functions**
```python
# Basic lambda
square = lambda x: x**2

# With map
squared = list(map(lambda x: x**2, [1, 2, 3, 4]))

# With filter
evens = list(filter(lambda x: x % 2 == 0, [1, 2, 3, 4]))

# With sorted
students = [("Alice", 25), ("Bob", 20), ("Charlie", 30)]
sorted_students = sorted(students, key=lambda x: x[1])
```

### Exception Handling

**Try-Except**
```python
# Basic exception handling
try:
    result = 10 / 0
except ZeroDivisionError:
    print("Cannot divide by zero")

# Multiple exceptions
try:
    # Some code
    pass
except (ValueError, TypeError) as e:
    print(f"Error: {e}")

# Generic exception
try:
    # Some code
    pass
except Exception as e:
    print(f"An error occurred: {e}")

# Try-except-else
try:
    result = 10 / 2
except ZeroDivisionError:
    print("Error")
else:
    print("Success")  # Runs if no exception

# Try-except-finally
try:
    file = open("file.txt")
    # Process file
except FileNotFoundError:
    print("File not found")
finally:
    # Always runs
    print("Cleanup")
```

**Raising Exceptions**
```python
# Raise exception
raise ValueError("Invalid value")

# Raise with condition
if x < 0:
    raise ValueError("x must be positive")

# Re-raise exception
try:
    # Some code
    pass
except Exception:
    # Log error
    raise  # Re-raise the same exception

# Custom exceptions
class CustomError(Exception):
    pass

raise CustomError("Something went wrong")
```

### File I/O

**Reading Files**
```python
# Read entire file
with open("file.txt", "r") as f:
    content = f.read()

# Read lines
with open("file.txt", "r") as f:
    lines = f.readlines()  # List of lines

# Iterate over lines
with open("file.txt", "r") as f:
    for line in f:
        print(line.strip())

# Read with encoding
with open("file.txt", "r", encoding="utf-8") as f:
    content = f.read()
```

**Writing Files**
```python
# Write (overwrite)
with open("file.txt", "w") as f:
    f.write("Hello World\n")
    f.writelines(["Line 1\n", "Line 2\n"])

# Append
with open("file.txt", "a") as f:
    f.write("New line\n")

# Write binary
with open("file.bin", "wb") as f:
    f.write(b'\x00\x01\x02')
```

**Working with Paths**
```python
import os
from pathlib import Path

# os module
os.path.exists("file.txt")
os.path.isfile("file.txt")
os.path.isdir("directory")
os.path.join("dir", "file.txt")
os.path.basename("/path/to/file.txt")  # "file.txt"
os.path.dirname("/path/to/file.txt")   # "/path/to"

# pathlib (modern approach)
path = Path("file.txt")
path.exists()
path.is_file()
path.read_text()
path.write_text("content")
path.parent
path.name
path.suffix  # ".txt"
```

---

## Advanced Features

### Object-Oriented Programming

**Classes and Objects**
```python
# Basic class
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def greet(self):
        return f"Hello, I'm {self.name}"

# Creating objects
person = Person("John", 30)
print(person.greet())

# Class variables vs instance variables
class Dog:
    species = "Canis familiaris"  # Class variable

    def __init__(self, name):
        self.name = name  # Instance variable

# Class methods and static methods
class MyClass:
    @classmethod
    def class_method(cls):
        return "Called on class"

    @staticmethod
    def static_method():
        return "Independent of class"
```

**Inheritance**
```python
# Single inheritance
class Animal:
    def __init__(self, name):
        self.name = name

    def speak(self):
        pass

class Dog(Animal):
    def speak(self):
        return f"{self.name} says Woof!"

# Multiple inheritance
class A:
    def method_a(self):
        return "A"

class B:
    def method_b(self):
        return "B"

class C(A, B):
    pass

# Method Resolution Order (MRO)
print(C.mro())

# super()
class Parent:
    def __init__(self, name):
        self.name = name

class Child(Parent):
    def __init__(self, name, age):
        super().__init__(name)
        self.age = age
```

**Special Methods (Dunder Methods)**
```python
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __str__(self):
        return f"Point({self.x}, {self.y})"

    def __repr__(self):
        return f"Point({self.x!r}, {self.y!r})"

    def __eq__(self, other):
        return self.x == other.x and self.y == other.y

    def __lt__(self, other):
        return (self.x**2 + self.y**2) < (other.x**2 + other.y**2)

    def __add__(self, other):
        return Point(self.x + other.x, self.y + other.y)

    def __len__(self):
        return 2

    def __getitem__(self, index):
        return [self.x, self.y][index]
```

**Properties and Descriptors**
```python
# Property decorator
class Person:
    def __init__(self, name):
        self._name = name

    @property
    def name(self):
        return self._name

    @name.setter
    def name(self, value):
        if not value:
            raise ValueError("Name cannot be empty")
        self._name = value

    @name.deleter
    def name(self):
        del self._name

# Using property()
class Person:
    def __init__(self, name):
        self._name = name

    def get_name(self):
        return self._name

    def set_name(self, value):
        self._name = value

    name = property(get_name, set_name)
```

**Abstract Base Classes**
```python
from abc import ABC, abstractmethod

class Animal(ABC):
    @abstractmethod
    def speak(self):
        pass

    @abstractmethod
    def move(self):
        pass

class Dog(Animal):
    def speak(self):
        return "Woof!"

    def move(self):
        return "Running"

# Cannot instantiate abstract class
# animal = Animal()  # TypeError
dog = Dog()
```

**Dataclasses (Python 3.7+)**
```python
from dataclasses import dataclass, field

@dataclass
class Person:
    name: str
    age: int
    email: str = "unknown"
    hobbies: list = field(default_factory=list)

person = Person("John", 30)
print(person)  # Person(name='John', age=30, email='unknown', hobbies=[])

# With methods
@dataclass
class Point:
    x: float
    y: float

    def distance(self, other):
        return ((self.x - other.x)**2 + (self.y - other.y)**2)**0.5

# Frozen (immutable)
@dataclass(frozen=True)
class ImmutablePoint:
    x: float
    y: float
```

### Decorators

**Function Decorators**
```python
# Basic decorator
def my_decorator(func):
    def wrapper(*args, **kwargs):
        print("Before function")
        result = func(*args, **kwargs)
        print("After function")
        return result
    return wrapper

@my_decorator
def greet(name):
    print(f"Hello, {name}")

# Decorator with arguments
def repeat(times):
    def decorator(func):
        def wrapper(*args, **kwargs):
            for _ in range(times):
                result = func(*args, **kwargs)
            return result
        return wrapper
    return decorator

@repeat(3)
def say_hello():
    print("Hello")

# functools.wraps (preserve metadata)
from functools import wraps

def my_decorator(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    return wrapper
```

**Common Built-in Decorators**
```python
# @property, @staticmethod, @classmethod (shown earlier)

# @functools.lru_cache (memoization)
from functools import lru_cache

@lru_cache(maxsize=128)
def fibonacci(n):
    if n < 2:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

# @functools.wraps (shown above)

# @contextlib.contextmanager
from contextlib import contextmanager

@contextmanager
def managed_resource():
    print("Acquiring resource")
    yield "resource"
    print("Releasing resource")

with managed_resource() as r:
    print(f"Using {r}")
```

### Iterators and Generators

**Iterators**
```python
# Creating an iterator
class Counter:
    def __init__(self, max):
        self.max = max
        self.count = 0

    def __iter__(self):
        return self

    def __next__(self):
        if self.count < self.max:
            self.count += 1
            return self.count
        raise StopIteration

counter = Counter(5)
for num in counter:
    print(num)

# iter() and next()
my_list = [1, 2, 3]
iterator = iter(my_list)
print(next(iterator))  # 1
print(next(iterator))  # 2
```

**Generators**
```python
# Generator function
def count_up_to(max):
    count = 1
    while count <= max:
        yield count
        count += 1

for num in count_up_to(5):
    print(num)

# Generator expression
squares = (x**2 for x in range(10))
print(next(squares))  # 0
print(next(squares))  # 1

# Generator with send()
def echo():
    while True:
        value = yield
        print(f"Received: {value}")

gen = echo()
next(gen)  # Prime the generator
gen.send("Hello")

# Infinite generator
def infinite_sequence():
    num = 0
    while True:
        yield num
        num += 1
```

### Context Managers

**Using Context Managers**
```python
# File handling (built-in)
with open("file.txt", "r") as f:
    content = f.read()

# Multiple context managers
with open("input.txt", "r") as infile, open("output.txt", "w") as outfile:
    content = infile.read()
    outfile.write(content)
```

**Creating Context Managers**
```python
# Using __enter__ and __exit__
class DatabaseConnection:
    def __enter__(self):
        print("Opening connection")
        self.conn = "connection"
        return self.conn

    def __exit__(self, exc_type, exc_val, exc_tb):
        print("Closing connection")
        if exc_type is not None:
            print(f"Exception occurred: {exc_val}")
        return False  # Re-raise exception

with DatabaseConnection() as conn:
    print(f"Using {conn}")

# Using contextlib
from contextlib import contextmanager

@contextmanager
def timer():
    import time
    start = time.time()
    yield
    end = time.time()
    print(f"Elapsed: {end - start:.2f}s")

with timer():
    # Some time-consuming operation
    sum(range(1000000))
```

### Modules and Packages

**Importing Modules**
```python
# Import entire module
import math
print(math.pi)

# Import specific items
from math import pi, sqrt
print(pi)

# Import with alias
import numpy as np
import pandas as pd

# Import all (not recommended)
from math import *

# Relative imports (within package)
from . import module
from .. import parent_module
from .sibling import function
```

**Creating Modules**
```python
# mymodule.py
def my_function():
    return "Hello"

MY_CONSTANT = 42

class MyClass:
    pass

# In another file
import mymodule
print(mymodule.my_function())
```

**Creating Packages**
```
mypackage/
    __init__.py
    module1.py
    module2.py
    subpackage/
        __init__.py
        module3.py
```

```python
# __init__.py
from .module1 import function1
from .module2 import function2

__all__ = ['function1', 'function2']

# Usage
from mypackage import function1
```

**Module Attributes**
```python
# __name__ for script vs module
if __name__ == "__main__":
    print("Running as script")
else:
    print("Imported as module")

# Other useful attributes
print(__file__)     # Module file path
print(__doc__)      # Module docstring
print(__package__)  # Package name
```

### Comprehensions and Functional Programming

**Advanced Comprehensions**
```python
# Nested list comprehension
matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
flat = [item for row in matrix for item in row]

# Set comprehension
unique_lengths = {len(word) for word in ["hello", "world", "hi"]}

# Dict comprehension with filtering
word_lengths = {word: len(word) for word in ["hello", "world"] if len(word) > 4}

# Generator expression
sum_of_squares = sum(x**2 for x in range(1000000))
```

**Built-in Functional Tools**
```python
# map()
squares = list(map(lambda x: x**2, [1, 2, 3, 4]))
# Or: squares = [x**2 for x in [1, 2, 3, 4]]

# filter()
evens = list(filter(lambda x: x % 2 == 0, range(10)))
# Or: evens = [x for x in range(10) if x % 2 == 0]

# reduce()
from functools import reduce
product = reduce(lambda x, y: x * y, [1, 2, 3, 4])  # 24

# zip()
names = ["Alice", "Bob"]
ages = [25, 30]
combined = list(zip(names, ages))  # [("Alice", 25), ("Bob", 30)]

# enumerate()
for i, value in enumerate(["a", "b", "c"]):
    print(f"{i}: {value}")

# all() and any()
all([True, True, True])   # True
any([False, False, True]) # True

# sorted()
sorted([3, 1, 4, 1, 5])
sorted(["banana", "apple"], key=len)
sorted(items, reverse=True)
```

### Regular Expressions

**Basic Pattern Matching**
```python
import re

# Search
match = re.search(r'\d+', 'Order 123')
if match:
    print(match.group())  # "123"

# Match (from beginning)
match = re.match(r'\d+', '123 abc')
print(match.group())  # "123"

# Find all
numbers = re.findall(r'\d+', 'Order 123 and 456')
print(numbers)  # ["123", "456"]

# Split
parts = re.split(r'\s+', 'hello   world')
print(parts)  # ["hello", "world"]

# Replace
text = re.sub(r'\d+', 'X', 'Order 123')
print(text)  # "Order X"
```

**Advanced Patterns**
```python
# Groups
match = re.search(r'(\d{3})-(\d{4})', 'Phone: 555-1234')
print(match.group(1))  # "555"
print(match.group(2))  # "1234"

# Named groups
match = re.search(r'(?P<area>\d{3})-(?P<number>\d{4})', '555-1234')
print(match.group('area'))  # "555"

# Lookahead and lookbehind
re.findall(r'\d+(?= dollars)', '100 dollars and 200 euros')  # ["100"]
re.findall(r'(?<=\$)\d+', '$100 and €200')  # ["100"]

# Flags
re.search(r'hello', 'HELLO', re.IGNORECASE)
re.search(r'^hello', 'hello\nworld', re.MULTILINE)
re.search(r'a.b', 'a\nb', re.DOTALL)

# Compile for reuse
pattern = re.compile(r'\d+')
pattern.findall('123 and 456')
```

### Collections Module

**Counter**
```python
from collections import Counter

# Count elements
counts = Counter(['a', 'b', 'a', 'c', 'b', 'a'])
print(counts)  # Counter({'a': 3, 'b': 2, 'c': 1})

# Most common
counts.most_common(2)  # [('a', 3), ('b', 2)]

# Operations
c1 = Counter(['a', 'b', 'c'])
c2 = Counter(['b', 'c', 'd'])
c1 + c2  # Combine
c1 - c2  # Subtract
c1 & c2  # Intersection
c1 | c2  # Union
```

**defaultdict**
```python
from collections import defaultdict

# With default factory
dd = defaultdict(list)
dd['key'].append(1)  # No KeyError

# Group items
words = ['apple', 'banana', 'apricot', 'blueberry']
grouped = defaultdict(list)
for word in words:
    grouped[word[0]].append(word)

# Count occurrences
counts = defaultdict(int)
for item in ['a', 'b', 'a', 'c']:
    counts[item] += 1
```

**OrderedDict**
```python
from collections import OrderedDict

# Maintains insertion order (Python 3.7+ dicts do this too)
od = OrderedDict()
od['first'] = 1
od['second'] = 2

# Move to end
od.move_to_end('first')

# Pop in order
od.popitem(last=False)  # FIFO
od.popitem(last=True)   # LIFO
```

**deque (Double-ended Queue)**
```python
from collections import deque

# Create deque
dq = deque([1, 2, 3])

# Add elements
dq.append(4)       # Add to right
dq.appendleft(0)   # Add to left

# Remove elements
dq.pop()           # Remove from right
dq.popleft()       # Remove from left

# Rotate
dq.rotate(1)       # Rotate right
dq.rotate(-1)      # Rotate left

# Max length (bounded deque)
dq = deque(maxlen=3)
dq.extend([1, 2, 3, 4])  # Only [2, 3, 4] kept
```

**namedtuple**
```python
from collections import namedtuple

# Create named tuple
Point = namedtuple('Point', ['x', 'y'])
p = Point(10, 20)

# Access by name or index
p.x        # 10
p[0]       # 10

# Convert to dict
p._asdict()  # {'x': 10, 'y': 20}

# Replace values (returns new tuple)
p2 = p._replace(x=15)
```

**ChainMap**
```python
from collections import ChainMap

# Combine multiple dicts
dict1 = {'a': 1, 'b': 2}
dict2 = {'b': 3, 'c': 4}
chain = ChainMap(dict1, dict2)

print(chain['a'])  # 1
print(chain['b'])  # 2 (from dict1, first in chain)
print(chain['c'])  # 4

# Add new dict to chain
dict3 = {'d': 5}
chain = chain.new_child(dict3)
```

### itertools Module

**Infinite Iterators**
```python
from itertools import count, cycle, repeat

# count(start, step)
for i in count(10, 2):  # 10, 12, 14, ...
    if i > 20:
        break

# cycle(iterable)
counter = 0
for item in cycle(['A', 'B', 'C']):
    if counter > 5:
        break
    print(item)
    counter += 1

# repeat(object, times)
list(repeat(10, 3))  # [10, 10, 10]
```

**Combinatoric Iterators**
```python
from itertools import (
    product, permutations, combinations, combinations_with_replacement
)

# Cartesian product
list(product([1, 2], ['a', 'b']))  # [(1,'a'), (1,'b'), (2,'a'), (2,'b')]

# Permutations
list(permutations([1, 2, 3], 2))  # [(1,2), (1,3), (2,1), (2,3), (3,1), (3,2)]

# Combinations
list(combinations([1, 2, 3], 2))  # [(1,2), (1,3), (2,3)]

# Combinations with replacement
list(combinations_with_replacement([1, 2], 2))  # [(1,1), (1,2), (2,2)]
```

**Other Iterators**
```python
from itertools import (
    chain, compress, dropwhile, takewhile, groupby,
    islice, zip_longest
)

# Chain iterables
list(chain([1, 2], [3, 4]))  # [1, 2, 3, 4]

# Compress (filter by boolean mask)
list(compress([1, 2, 3, 4], [1, 0, 1, 0]))  # [1, 3]

# Drop/take while condition is true
list(dropwhile(lambda x: x < 5, [1, 4, 6, 3, 8]))  # [6, 3, 8]
list(takewhile(lambda x: x < 5, [1, 4, 6, 3, 8]))  # [1, 4]

# Group by key
data = [('A', 1), ('A', 2), ('B', 3), ('B', 4)]
for key, group in groupby(data, key=lambda x: x[0]):
    print(key, list(group))

# Slice iterator
list(islice(range(10), 2, 8, 2))  # [2, 4, 6]

# Zip longest (pad missing values)
list(zip_longest([1, 2], ['a', 'b', 'c'], fillvalue=0))
# [(1, 'a'), (2, 'b'), (0, 'c')]
```

### Asyncio (Async/Await)

**Basic Async Operations**
```python
import asyncio

# Define async function
async def fetch_data():
    await asyncio.sleep(1)  # Simulate I/O
    return "Data"

# Run async function
result = asyncio.run(fetch_data())

# Multiple async operations
async def main():
    task1 = asyncio.create_task(fetch_data())
    task2 = asyncio.create_task(fetch_data())

    result1 = await task1
    result2 = await task2

    return result1, result2

asyncio.run(main())
```

**Async Context Managers**
```python
class AsyncResource:
    async def __aenter__(self):
        await asyncio.sleep(0.1)
        return self

    async def __aexit__(self, exc_type, exc, tb):
        await asyncio.sleep(0.1)

async def main():
    async with AsyncResource() as resource:
        print("Using resource")

asyncio.run(main())
```

**Async Iterators**
```python
class AsyncCounter:
    def __init__(self, max):
        self.max = max
        self.count = 0

    def __aiter__(self):
        return self

    async def __anext__(self):
        if self.count < self.max:
            await asyncio.sleep(0.1)
            self.count += 1
            return self.count
        raise StopAsyncIteration

async def main():
    async for num in AsyncCounter(5):
        print(num)

asyncio.run(main())
```

**Gather and Wait**
```python
async def main():
    # Gather - run concurrently, get all results
    results = await asyncio.gather(
        fetch_data(),
        fetch_data(),
        fetch_data()
    )

    # Wait - more control
    tasks = [asyncio.create_task(fetch_data()) for _ in range(3)]
    done, pending = await asyncio.wait(tasks)

    # Wait for first completion
    done, pending = await asyncio.wait(
        tasks,
        return_when=asyncio.FIRST_COMPLETED
    )
```

### Type Hints and Annotations

**Basic Type Hints**
```python
# Variables
name: str = "John"
age: int = 30
price: float = 19.99
is_active: bool = True

# Functions
def greet(name: str) -> str:
    return f"Hello, {name}"

# Collections
from typing import List, Dict, Tuple, Set

names: List[str] = ["Alice", "Bob"]
ages: Dict[str, int] = {"Alice": 25, "Bob": 30}
point: Tuple[int, int] = (10, 20)
unique: Set[int] = {1, 2, 3}
```

**Advanced Type Hints**
```python
from typing import (
    Optional, Union, Any, Callable, TypeVar, Generic,
    Iterable, Sequence, Mapping
)

# Optional (can be None)
def get_user(id: int) -> Optional[str]:
    return None

# Union (multiple types)
def process(value: Union[int, str]) -> str:
    return str(value)

# Any
def process_any(value: Any) -> Any:
    return value

# Callable
def apply(func: Callable[[int, int], int], a: int, b: int) -> int:
    return func(a, b)

# Generic types
T = TypeVar('T')

def first(items: List[T]) -> T:
    return items[0]

# Generic class
class Box(Generic[T]):
    def __init__(self, item: T):
        self.item = item

    def get(self) -> T:
        return self.item

# Protocol (structural subtyping)
from typing import Protocol

class Drawable(Protocol):
    def draw(self) -> None:
        ...
```

### Popular Standard Library Modules

**datetime**
```python
from datetime import datetime, date, time, timedelta

# Current date/time
now = datetime.now()
today = date.today()

# Create datetime
dt = datetime(2024, 1, 15, 14, 30, 0)

# Format and parse
formatted = now.strftime("%Y-%m-%d %H:%M:%S")
parsed = datetime.strptime("2024-01-15", "%Y-%m-%d")

# Timedelta
tomorrow = today + timedelta(days=1)
week_ago = now - timedelta(weeks=1)

# Comparison
if date1 < date2:
    print("date1 is earlier")
```

**json**
```python
import json

# Serialize to JSON
data = {"name": "John", "age": 30}
json_str = json.dumps(data)
json_str = json.dumps(data, indent=2)

# Deserialize from JSON
data = json.loads(json_str)

# File operations
with open("data.json", "w") as f:
    json.dump(data, f, indent=2)

with open("data.json", "r") as f:
    data = json.load(f)
```

**random**
```python
import random

# Random numbers
random.random()           # 0.0 to 1.0
random.randint(1, 10)     # 1 to 10 inclusive
random.uniform(1.0, 10.0) # Float between 1.0 and 10.0

# Random choice
random.choice([1, 2, 3, 4])
random.sample([1, 2, 3, 4, 5], 3)  # 3 unique items

# Shuffle
items = [1, 2, 3, 4, 5]
random.shuffle(items)

# Seed for reproducibility
random.seed(42)
```

**urllib and requests**
```python
# urllib (standard library)
from urllib.request import urlopen
from urllib.parse import urlencode, parse_qs

response = urlopen('https://api.example.com')
data = response.read()

# requests (third-party, preferred)
import requests

response = requests.get('https://api.example.com')
print(response.status_code)
print(response.json())

# POST request
response = requests.post('https://api.example.com', json={'key': 'value'})

# Headers
headers = {'Authorization': 'Bearer token'}
response = requests.get('https://api.example.com', headers=headers)
```

**argparse**
```python
import argparse

parser = argparse.ArgumentParser(description='Process some data')

# Positional argument
parser.add_argument('input', help='Input file')

# Optional argument
parser.add_argument('-o', '--output', help='Output file')
parser.add_argument('-v', '--verbose', action='store_true')
parser.add_argument('-n', '--number', type=int, default=1)

args = parser.parse_args()
print(args.input)
print(args.output)
print(args.verbose)
```

**logging**
```python
import logging

# Basic configuration
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    filename='app.log'
)

# Log messages
logging.debug('Debug message')
logging.info('Info message')
logging.warning('Warning message')
logging.error('Error message')
logging.critical('Critical message')

# Custom logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

# Handler
handler = logging.FileHandler('custom.log')
handler.setFormatter(
    logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
)
logger.addHandler(handler)
```

**subprocess**
```python
import subprocess

# Run command
result = subprocess.run(['ls', '-l'], capture_output=True, text=True)
print(result.stdout)
print(result.returncode)

# With shell
result = subprocess.run('ls -l | grep py', shell=True, capture_output=True)

# Check for errors
try:
    subprocess.run(['false'], check=True)
except subprocess.CalledProcessError as e:
    print(f"Command failed with code {e.returncode}")

# Pipe between commands
p1 = subprocess.Popen(['ls'], stdout=subprocess.PIPE)
p2 = subprocess.Popen(['grep', 'py'], stdin=p1.stdout, stdout=subprocess.PIPE)
output = p2.communicate()[0]
```

### Testing

**unittest**
```python
import unittest

class TestMath(unittest.TestCase):
    def setUp(self):
        # Runs before each test
        self.x = 10

    def tearDown(self):
        # Runs after each test
        pass

    def test_addition(self):
        self.assertEqual(2 + 2, 4)
        self.assertNotEqual(2 + 2, 5)

    def test_types(self):
        self.assertIsInstance(self.x, int)
        self.assertTrue(self.x > 0)
        self.assertIn(1, [1, 2, 3])

    def test_exceptions(self):
        with self.assertRaises(ZeroDivisionError):
            1 / 0

if __name__ == '__main__':
    unittest.main()
```

**pytest (third-party)**
```python
# test_example.py
import pytest

def test_addition():
    assert 2 + 2 == 4

def test_strings():
    assert "hello".upper() == "HELLO"

# Fixtures
@pytest.fixture
def sample_data():
    return [1, 2, 3, 4, 5]

def test_with_fixture(sample_data):
    assert len(sample_data) == 5

# Parametrize
@pytest.mark.parametrize("input,expected", [
    (2, 4),
    (3, 9),
    (4, 16)
])
def test_square(input, expected):
    assert input ** 2 == expected

# Run with: pytest test_example.py
```

**doctest**
```python
def add(a, b):
    """
    Add two numbers.

    >>> add(2, 3)
    5
    >>> add(-1, 1)
    0
    """
    return a + b

if __name__ == "__main__":
    import doctest
    doctest.testmod()
```

### Performance and Optimization

**timeit**
```python
import timeit

# Time a statement
time = timeit.timeit('[x**2 for x in range(100)]', number=10000)
print(f"Time: {time:.4f}s")

# Time a function
def my_function():
    return sum(range(100))

time = timeit.timeit(my_function, number=10000)

# Compare alternatives
time1 = timeit.timeit('"-".join([str(i) for i in range(100)])', number=10000)
time2 = timeit.timeit('"-".join(map(str, range(100)))', number=10000)
```

**cProfile**
```python
import cProfile
import pstats

def slow_function():
    total = 0
    for i in range(1000):
        total += i ** 2
    return total

# Profile code
cProfile.run('slow_function()')

# Profile to file
cProfile.run('slow_function()', 'profile_stats')

# Analyze stats
stats = pstats.Stats('profile_stats')
stats.sort_stats('cumulative')
stats.print_stats(10)  # Top 10
```

**Memory Profiling**
```python
# Using sys
import sys
obj = [1, 2, 3, 4, 5]
print(sys.getsizeof(obj))  # Bytes

# Using tracemalloc
import tracemalloc

tracemalloc.start()

# Code to profile
data = [i for i in range(1000000)]

snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')

for stat in top_stats[:3]:
    print(stat)

tracemalloc.stop()
```

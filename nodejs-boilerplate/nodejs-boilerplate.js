#!/usr/bin/env node
/**
 * Node.js Boilerplate - Essential Syntax Reference
 */

// Importing libraries (CommonJS)
const fs = require('fs');
const path = require('path');

// Importing libraries (ES6 modules - uncomment if using "type": "module" in package.json)
// import fs from 'fs';
// import path from 'path';

// Constants
const APP_NAME = 'Node.js Boilerplate';
const VERSION = '1.0.0';


// Classes
class Person {
    constructor(name, age) {
        this.name = name;
        this.age = age;
    }

    greet() {
        return `Hello, my name is ${this.name} and I'm ${this.age} years old.`;
    }

    isAdult() {
        return this.age >= 18;
    }
}


// Functions
function addNumbers(a, b) {
    return a + b;
}

// Arrow function
const multiplyNumbers = (a, b) => a * b;

// Function with default parameters
function greetUser(name = 'Guest', greeting = 'Hello') {
    return `${greeting}, ${name}!`;
}

// Function demonstrating array operations
function processList(items) {
    if (!items || items.length === 0) {
        return { sum: 0, average: 0, max: null, min: null };
    }

    const sum = items.reduce((acc, val) => acc + val, 0);

    return {
        sum: sum,
        average: sum / items.length,
        max: Math.max(...items),
        min: Math.min(...items)
    };
}


// Conditional statements
function demonstrateConditionals(value) {
    let result;

    // If-else if-else
    if (value > 0) {
        result = 'positive';
    } else if (value < 0) {
        result = 'negative';
    } else {
        result = 'zero';
    }

    // Ternary operator
    const parity = value % 2 === 0 ? 'even' : 'odd';

    // Switch statement
    let category;
    switch (true) {
        case value > 100:
            category = 'large';
            break;
        case value > 10:
            category = 'medium';
            break;
        default:
            category = 'small';
    }

    return `${value} is ${result}, ${parity}, and ${category}`;
}


// Loop demonstrations
function demonstrateLoops() {
    console.log('\n=== For Loop ===');
    // Traditional for loop
    for (let i = 0; i < 5; i++) {
        console.log(`Count: ${i}`);
    }

    console.log('\n=== For...of Loop (Arrays) ===');
    // For...of loop (values)
    const fruits = ['apple', 'banana', 'cherry'];
    for (const fruit of fruits) {
        console.log(`Fruit: ${fruit}`);
    }

    console.log('\n=== For...of with entries ===');
    // For...of with entries (index and value)
    for (const [index, fruit] of fruits.entries()) {
        console.log(`${index}: ${fruit}`);
    }

    console.log('\n=== forEach ===');
    // forEach
    fruits.forEach((fruit, index) => {
        console.log(`${index}: ${fruit}`);
    });

    console.log('\n=== While Loop ===');
    // While loop
    let count = 0;
    while (count < 3) {
        console.log(`While count: ${count}`);
        count++;
    }

    console.log('\n=== Array Methods (map, filter, reduce) ===');
    // Map
    const numbers = [1, 2, 3, 4, 5];
    const squares = numbers.map(x => x ** 2);
    console.log(`Squares: ${squares}`);

    // Filter
    const evenNumbers = numbers.filter(x => x % 2 === 0);
    console.log(`Even numbers: ${evenNumbers}`);

    // Reduce
    const sum = numbers.reduce((acc, val) => acc + val, 0);
    console.log(`Sum: ${sum}`);
}


// Data structures
function demonstrateDataStructures() {
    console.log('\n=== Arrays ===');
    const myArray = [1, 2, 3, 4, 5];
    myArray.push(6);
    myArray.unshift(0); // Add to beginning
    console.log(`Array: ${myArray}`);
    console.log(`Array length: ${myArray.length}`);

    console.log('\n=== Objects ===');
    const myObject = {
        name: 'John',
        age: 30,
        city: 'New York'
    };
    myObject.country = 'USA';
    myObject['email'] = 'john@example.com';
    console.log('Object:', myObject);

    // Object iteration
    console.log('Object keys:');
    for (const key in myObject) {
        console.log(`  ${key}: ${myObject[key]}`);
    }

    // Object methods
    console.log('Keys:', Object.keys(myObject));
    console.log('Values:', Object.values(myObject));
    console.log('Entries:', Object.entries(myObject));

    console.log('\n=== Maps ===');
    const myMap = new Map();
    myMap.set('name', 'Alice');
    myMap.set('age', 25);
    console.log('Map size:', myMap.size);
    console.log('Map has name?', myMap.has('name'));

    for (const [key, value] of myMap) {
        console.log(`  ${key}: ${value}`);
    }

    console.log('\n=== Sets ===');
    const mySet = new Set([1, 2, 3, 4, 5]);
    mySet.add(6);
    mySet.add(3); // Duplicates are ignored
    console.log('Set:', [...mySet]);
    console.log('Set size:', mySet.size);
}


// Destructuring and spread operator
function demonstrateModernSyntax() {
    console.log('\n=== Destructuring ===');

    // Array destructuring
    const [first, second, ...rest] = [1, 2, 3, 4, 5];
    console.log(`First: ${first}, Second: ${second}, Rest: ${rest}`);

    // Object destructuring
    const person = { name: 'Bob', age: 35, city: 'Boston' };
    const { name, age } = person;
    console.log(`Name: ${name}, Age: ${age}`);

    console.log('\n=== Spread Operator ===');
    const arr1 = [1, 2, 3];
    const arr2 = [4, 5, 6];
    const combined = [...arr1, ...arr2];
    console.log(`Combined array: ${combined}`);

    const obj1 = { a: 1, b: 2 };
    const obj2 = { c: 3, d: 4 };
    const combinedObj = { ...obj1, ...obj2 };
    console.log('Combined object:', combinedObj);
}


// Error handling
function demonstrateErrorHandling() {
    console.log('\n=== Error Handling ===');

    // Try-catch
    try {
        const result = 10 / 2;
        console.log(`Division result: ${result}`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
    } finally {
        console.log('Finally block executed');
    }

    // Try-catch with specific error
    try {
        const data = JSON.parse('{"name": "test"}');
        console.log('Parsed JSON:', data);
    } catch (error) {
        if (error instanceof SyntaxError) {
            console.error('Invalid JSON');
        } else {
            console.error('Unexpected error:', error);
        }
    }

    // Throwing custom errors
    function validateAge(age) {
        if (age < 0) {
            throw new Error('Age cannot be negative');
        }
        return age;
    }

    try {
        validateAge(25);
        console.log('Age validation passed');
    } catch (error) {
        console.error(error.message);
    }
}


// Async/Promises
async function demonstrateAsync() {
    console.log('\n=== Async/Promises ===');

    // Promise example
    const simplePromise = new Promise((resolve, reject) => {
        setTimeout(() => {
            resolve('Promise resolved!');
        }, 100);
    });

    simplePromise.then(result => {
        console.log(result);
    });

    // Async/await
    const asyncFunction = async () => {
        return 'Async result';
    };

    const result = await asyncFunction();
    console.log(result);

    // Multiple async operations
    const promise1 = Promise.resolve(1);
    const promise2 = Promise.resolve(2);
    const promise3 = Promise.resolve(3);

    const results = await Promise.all([promise1, promise2, promise3]);
    console.log('Promise.all results:', results);
}


// File operations
function demonstrateFileOperations() {
    console.log('\n=== File Operations ===');

    const filename = 'temp_example.txt';

    // Writing to file (synchronous)
    fs.writeFileSync(filename, 'Hello, World!\nThis is a test file.\n');
    console.log(`Written to ${filename}`);

    // Reading from file (synchronous)
    const content = fs.readFileSync(filename, 'utf8');
    console.log('File content:');
    console.log(content);

    // Reading file (asynchronous)
    fs.readFile(filename, 'utf8', (err, data) => {
        if (err) {
            console.error('Error reading file:', err);
            return;
        }
        console.log('Async read successful');
    });

    // Check if file exists
    if (fs.existsSync(filename)) {
        fs.unlinkSync(filename);
        console.log(`Removed ${filename}`);
    }
}


// Main function
async function main() {
    console.log(`=== ${APP_NAME} v${VERSION} ===`);
    console.log(`Started at: ${new Date().toISOString()}\n`);

    // Using a class
    const person = new Person('Alice', 25);
    console.log(person.greet());
    console.log(`Is adult? ${person.isAdult()}\n`);

    // Using functions
    console.log(`Add 5 + 3 = ${addNumbers(5, 3)}`);
    console.log(`Multiply 5 * 3 = ${multiplyNumbers(5, 3)}`);
    console.log(greetUser('John', 'Hi'));
    console.log(greetUser()); // Using defaults

    const numbers = [1, 2, 3, 4, 5];
    const stats = processList(numbers);
    console.log('\nList stats:', stats);

    // Conditionals
    console.log(`\n${demonstrateConditionals(10)}`);
    console.log(demonstrateConditionals(-5));
    console.log(demonstrateConditionals(0));

    // Loops
    demonstrateLoops();

    // Data structures
    demonstrateDataStructures();

    // Modern syntax
    demonstrateModernSyntax();

    // Error handling
    demonstrateErrorHandling();

    // Async operations
    await demonstrateAsync();

    // File operations
    demonstrateFileOperations();

    console.log(`\n=== Program completed at: ${new Date().toISOString()} ===`);
}


// Run main function
if (require.main === module) {
    main().catch(console.error);
}

// Export for use as module
module.exports = {
    Person,
    addNumbers,
    multiplyNumbers,
    processList,
    demonstrateConditionals
};

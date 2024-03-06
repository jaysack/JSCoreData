# JSCoreData

JSCoreData is a CoreData wrapper that allows you to read, write, update, and delete objects without all the usually necessary boilerplate code to use CoreData.

<br>

## Table of Contents

- [Installation](#installation)
- [How It Works](#how-it-works)
- [Filter Results](#filter-results)
- [Automation (advanced)](#automation-advanced)

<br>

## Installation

To install `JSCoreData` to your project, simply add the following dependency to your project with Swift Package Manager.

```swift
.package(url: "https://github.com/jaysack/JSCoreData.git", .upToNextMajor(from: "1.0.0"))
```

<br>

## How It Works

For this example, we'll persist a simple `Person` object so we can retrieve it later.

```swift
struct Person {

    let id: String
    let name: String
    let age: Int

    init(id: String = UUID().uuidString, name: String, age: Int) {
        self.id = id
        self.name = name
        self.age = age
    }

}
```

<br>

### 1. Create a _.xcdatamodeld_ File

CoreData needs a place to look up entity classes. When using JSCoreData, this is no different.  
Let's create our .xcdatamodeld file that we'll name _Entities_.

<img src="https://github.com/kigalisoftware/kscoredata-swift/assets/44855831/d45d8143-acf9-4e3b-8464-bddd721e914f" width=700>

<br>

### 2. Create a Person entity

In our _Entities.xcdatamodeld_ file, we create our `Person` entity that will be stored in the persistent layer.

> We recommend that you add the suffix **_CoreData_** to your entity names so that you can quickly identify it and not confuse it with your domain model `Person`.

> We also recommend (although not required) that you add an `id` attribute to your entities.

<img src="https://github.com/kigalisoftware/kscoredata-swift/assets/44855831/4e2eda05-5346-4b14-bde3-082625b29d54" width=700>

<br>

### 3. Build the Project

Building the project at this stage will automatically generate NSManagedObject classes needed for CoreData to work properly.

<br>

### 4. Create a _CoreDataModel+Extension.swift_ file

Create a file that will contain extensions for your CoreData entity classes.  
For now, we're doing this manually but we will see how to automate this process later.
<br>
In that file, create an extension to conform `PersonCoreData` to `JSCoreDataEntityProtocol`.

<img src="https://github.com/kigalisoftware/kscoredata-swift/assets/44855831/3815fc7b-c153-422c-841d-ab1334ea8b11" width=700>

<br>

### 5. Conform `Person` to `JSCoreDataCodable`

If you're somehow familiar with Swift, you know that Codable is the protocol used to allow parsing and decoding network objects.
<br>
Here `JSCoreDataCodable` has a similar process and allow you to "decode" objects from managed object representations.

1. We first import `CoreData`
2. We conform `Person` to `JSCoreDataCodable`

```swift
extension Person: JSCoreDataCodable {

    typealias CoreDataModel = PersonCoreData

    // Init from 'CoreDataModel' managed object representation
    init?(coreDataModel: PersonCoreData?) {
        guard let coreDataModel,
              let id = coreDataModel.id,
              let name = coreDataModel.name
        else { return nil }
        self.id = id
        self.name = name
        self.age = Int(coreDataModel.age)
    }

    // Set core data model's attributes
    func setCoreDataModel(_ coreDataModel: inout PersonCoreData, inContext context: NSManagedObjectContext) {
        coreDataModel.id = id
        coreDataModel.name = name
        coreDataModel.age = Int16(age)
    }

    // Check equality between the domain model and managed object representation
    func isEqual(to coreDataObject: PersonCoreData) -> Bool {
        guard id == coreDataObject.id else { return false }
        guard name == coreDataObject.name else { return false }
        guard age == coreDataObject.age else { return false }
        return true
    }
}
```

<br>

### 6. Use JSCoreData Object

And that's it!  
Now all you need to do is using an instance of `JSCoreData` to run your CRUD operations as follows:  
You can now persist your objects using a single line.

```swift
    // KSCoreDataManager instance
    let coreDataManager = JSCoreData(persistentContainer: "Entities")

    // Some test data
    let people: [Person] = [
        Person(name: "John", age: 32),
        Person(name: "Peter", age: 31),
        Person(name: "Marie", age: 19),
        Person(name: "Liz", age: 62),
        Person(name: "Isaac", age: 26)
    ]

    // Saving objects
    for person in people {
        try! coreDataManager.setObject(person)
    }
```

<br>

And, you can retrieve them with a single line as well!

```swift
let savedPeople: [Person] = try! coreDataManager.getObjects()

// John, 32
// Peter, 31
// Marie, 19
// Liz, 62
// Isaac, 26
```

<br>

## Filter Results

In some cases you might want to filter the results returned by the CoreData layer.  
JSCoreData makes it easy to do this with our beloved (or not beloved) `NSPredicate` object!  
When using JSCoreDataManager, you can specify a predicate to filter results as follows:

```swift
let predicate = NSPredicate(format: "age > %i", 30)
let peopleOlderThan30: [Person] = try! coreDataManager.getObjects(matching: predicate)

// John, 32
// Peter, 31
// Liz, 62
```
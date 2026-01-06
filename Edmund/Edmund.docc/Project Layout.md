# Project Layout

The Edmund code base is dividied into logical groups, of which are defined in this document.

## Overview

There are three main targets within the Edmund greater project:
- Edmund: The macOS, iOS, and iPadOS app, containing all UI and backend code.
- EdmundTests: The unit tests for Edmunds's backend operations.
- EdmundUITests: The tests for Edmund's UI, and interactions of it with the backend.

The majority of the code is within the Edmund target. Currently (as of 1/5/26), this is divided into the following major sections:

| Section Name | Compile Sources? |                                                              Description                                                             |
|--------------|------------------|--------------------------------------------------------------------------------------------------------------------------------------|
|    Models    |      Yes         | Code that contains the Core Data information, tools for working with it, and functionality built on model classes.                   |
|   Resources  |       No         | Files, resources, and other files used for Edmund's UI appearance, localizations, and runtime dependencies.                          |
|    Tools     |      Yes         | General code that does not fall within the frontend or backend, but is used by either.                                               |
|    Views     |      Yes         | The bulk of Edmund; A folder that contains all UI code and logic.                                                                    |
|   Widgets    |      Yes         | A series of code files that were used for widgets. This is mostly not included as compile sources, but are used by homescreen views. |

The following sections will go over the contents of each major section.

## Major Section Breakdown
### Models
The models section is designed to contain information for backend logic and operations. As Edmund is built on CoreData, most of this functionality is built around Core Data. One of the first things to notice is that all information is organized based on type groups. 

### Resources

### Tools

### Views

### Widgets

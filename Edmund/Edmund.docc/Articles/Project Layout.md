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

All schema information is contained within the `Schema` directory. Currently, there is only one schema. This folder has also historically stored the class instances for Swift Data. After the migration to Core Data, the directory is there just in case.

The `Containers` file contains all information relating to the Core Data stack, the most notable being ``DataStack``.

### Resources
This directory contains Edmund's non-code resources. For instance, it contains localization resources, icons, and other related files. The icons are represented in both SVG and PNG formats. The SVG is in [Inkscape](https://inkscape.org) format. 

### Tools
Edmund has a series of types that are designed to help the entire app, and they are stored here. These types generally do not belong in specficially the frontend or backend, so they live here.

### Views
The bulk of Edmund is stored here. This includes the pure frontend code, and the connection between the front and back ends. Most of the code here are Swift UI views, but the rest is typically View Model code. 

Most of the code in this directory is laid out the same way the views are laid out. This means that if a file is closer to the root of the view directory, it will be higher in the view hiearchy. 

### Widgets
A historical directory that contained widget tools. Edmund used to include widgets, but due to production releasing reasons, the idea was scrapped. However, widgets are planned for the future, so these tools persist. 

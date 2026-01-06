# Using Selection
A guide on using the selection system present in Edmund.

## Overview

Edmund often presents data in table or list format. In addition, the data is usually selectable, and supports inspection, editing, deleting, and adding. (See <doc:Editing,-Selecting,-and-Adding-Elements> and <doc:Deleting-Elements>). Since there are so many places this pattern is presented, work has been done to simplify the process. This collection of tools is called Selection Tools.  

## Defining Selection

Selection refers to a collection of data in combination with a set of IDs. The IDs represent which elements of the collection are "selected". This data is usually infered to be pulled from the UI. These two are given together in a context. There are two different contexts: ``SelectionContext`` and ``FrozenSelectionContext``. The only difference is that ``SelectionContext`` contains a live binding to the selection, while ``FrozenSelectionContext`` contains a static, owned selection set. They are related by thte ``SelectionContextProtocol``, which allows the two to be interchangable. 

In addition, the there are property wrappers that produce ``SelectionContext`` values. These wrappers hide the details of selection and data presentation/management. However, all of them can be used with inspection and deleting manifests. Here is a list of the current property wrappers:
|              Name            | Dynamic? |                                       Description                                                     |
|------------------------------|----------|-------------------------------------------------------------------------------------------------------|
|       ``QuerySelection``     |    Yes   | Fetches data from Core Data over a specific data type.                                                |
| ``FilterableQuerySelection`` |    Yes   | Fetches data from Core data over a specific data type, but additionally performs in-memory filtering. |
|      ``SourcedSelection``    |    No    | Contains a pre-determined, updatable data source.                                                     |


*Note*: The "Dynamic?" column indicates if the data updates/manages its data from an external source.

These property wrappers provide an instance of ``SelectionContext`` from their `wrappedValue` properties. Therefore, the value of using a specific property wrapper is always `SelectionContext<T>`. For instance:

```swift
@QuerySelection<Bill> var bills: SelectionContext<Bill>;
```

## Using Selections
It is possible to extract the data from the selection directy from ``SelectionContext``. Using ``SelectionContextProtocol/selectedItems`` will grab the items from the stored data and current selection set. These instances represent what is selected from the UI. 

However, it is more common to see the ``SelectionContext`` to be directly passed into the UI. Edmund includes different constructors for ``SwiftUI/Table`` and ``SwiftUI/List``. These constructors are as follows:
- ``SwiftUI/Table/init(context:columns:)``: Constructs a table around a context.
- ``SwiftUI/Table/init(context:sortOrder:columns:)``: Constructs a sortable table around a context.
- ``SwiftUI/List/init(context:rowContent:)``: Constructs a list around a context.

Using these constructors allows the developer to present and manage selection contexts directly, without having to hook directly to the contents of the property. When this is used, the data is presented (according to the `columns` or `rowContent` values), and selection is automatically bound against the property wrapper. For example:

```swift
struct BillsPresenter: View {
    @QuerySelection<Bill> var bills: SelectionContext<Bill>;

    var body: some View {
        Table(bills) {
            TableColumn("Name", value: \.name)
            TableColumn("Amount") { bill in 
                Text(bill.amount, format: .currency(code: "USD"))
            }
        }
    }
}
```

Whenever `BillsPresenter` is called, it will fetch the bills out of Core Data, and then present it with selection enabled. 

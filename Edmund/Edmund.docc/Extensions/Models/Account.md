# ``Edmund/Account``

A representation of a physical store of money.

## Overview

Accounts represent real live money stores. This could be at a bank, with an investment firm, or even cash.

Internally, ``Account`` is an objective-c class. However, extensions provide the swift (and SwiftUI) presentable properties. For example, look at ``Account/name`` vs ``Account/internalName``. ``Account/name`` is of type `String`, while ``Account/internalName`` is of type `String?`. It is designed that ``Account/internalName`` can never be `nil`, but ``Account/name`` presents this in a more structured format. Any variable named `internal*` is an objective-c and swift visible type, while the corresponding variable without the `internal` prefix represents a swift only variable. Take care when sorting or filtering based on this type to only use objective-c visible properties.

## Topics

### Properties

- ``Account/name``
- ``Account/internalName``
- ``Account/creditLimit``
- ``Account/internalCreditLimit``
- ``Account/interest``
- ``Account/internalInterest``
- ``Account/kind``
- ``Account/internalKind``
- ``Account/location``
- ``Account/envolopes``
- ``Account/internalEnvolopes``

### Debug Information
- ``Account/exampleAccounts(cx:)`` 

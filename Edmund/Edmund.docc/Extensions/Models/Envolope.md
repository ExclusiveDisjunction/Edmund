# ``Edmund/Envolope``

A logical separation of balances from a greater account.

## Overview

Envolopes are balance holders; they store the transactions on behalf of an account. Unlike accounts, they cannot exist on their own. An account has at least one envolope if it has a balance. Envolopes serve to help ensure that specific balances are kept, while easily tracking the flow of money.

## Topics

### Properties
- ``Envolope/desc``
- ``Envolope/internalName``
- ``Envolope/name``
- ``Envolope/isVoided``

### Relationships
- ``Envolope/account``
- ``Envolope/devotions``
- ``Envolope/divisions``
- ``Envolope/savings``
- ``Envolope/ledger``
- ``Envolope/transactions``

### Debug Examples
- ``Envolope/examples(cx:)``

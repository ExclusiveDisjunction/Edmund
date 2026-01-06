# Type Groups

Explination of the high level structure of Edmund's data.

## Overview

Edmund uses a lot of different, but related, data representations. Both the backend and frontend interact with said data. The backend is used to represent and manage the data, while the frontend presents it, and signals intent to edit the data. 

Knowing this, it makes sense to group the data Edmund contains into logical groups. These are called the **Type Groups**. The type groups are as follows:

| Group Name   | Notable Classes                                    | Description                                                     | 
|--------------|----------------------------------------------------|-----------------------------------------------------------------|
| Bills        | ``Bill``, ``BillDatapoint``                        | Information about recourring charges with histories.            |
| Budget       | ``Budget``, ``IncomeDivision``, ``IncomeDevotion`` | Logical breakdowns of income and where it will be spent/stored. |
| Jobs         | ``IncomeSource``, ``TraditionalJob``               | Information representing income, repeating or not.              |
| Organization | ``Account``, ``Envolope``, ``Category``            | Separation of balances and grouping of transactions.            |
| Ledger       | ``LedgerEntry``                                    | Encoding of balances via entries of a ledger.                   |

*Note*: Sometimes, the organization and ledger groups are combined into one major group: Balances. This is due to the deep connection between the two groups. However, the UI sepearates the two, due to the higher quantity of views relating to the ledger.

*Note*: Historically, the income group was separate from the budget group. However, it was realized that the information encoded in ``IncomeDivision`` was very similar to the income representation in ``Budget``. Therefore, the ``Budget`` class assumed ownership of ``IncomeDivision``. Therefore, the two are combined into one major group.

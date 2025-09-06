***Note***: This is a beta version. Data format is not guaranteed to be persistent across versions. 

## New Features
1. Many-to-many transfers have been redesigned. 
## Notes
This release contains no extra notes.

## Bug Fixes
### Level 1 - Cosmetic
1. On iOS & iPadOS, when looking at all jobs, the condensed information is compacted & hard to read. Correction: When displaying all jobs, only the job’s name appears. All other information can be viewed by inspecting.
2. Finalize, when looking at all income divisions, was spelled incorrectly.
3. The properties width when adding a sub category on iOS/iPadOS was too small.
4. When doing a one-to-one transfer, many-to-one transfer, and many-to-many
5. The columns for the ledger are more evenly distributed based on the data they contain.
6. After creating a One to Many transfer, the “Various to \_” transaction (the one that takes the money out of the source) appears AFTER the deposits to the other accounts. This has been fixed to be the other way around (it makes more sense)

### Level 2 - Minor Annoyance
1. The credit card audit tool does not display the correct available credit on startup, and does not show the proper balance when putting in the available credit.
2. When opening the initial balance transaction template, the payday work-in-progress template opens instead.
3. When editing an income division, the error “Please fill in all fields will” will be shown if there is no remainder active.
4. 5. The ledger, when in compact mode, does not have a context menu.
5. When performing a many-to-many transfer, the transactions would not be filled out correctly in the ledger.
### Level 3 - Noticeable Issues 
1. On all platforms, bills & utilities do not update their frequency/period and autopay properties when adding or editing.
2. If a unique constrained element (Accounts, Sub Accounts, Categories, Sub Categories, Bills, Subscriptions, Hourly & Salaried Jobs, and Utilities) was deleted, and then adding a new element of the same type, with the same unique ID, Edmund will say the element is not unique.
3. When on iOS & iPadOS, with compact screen sizes, the bills & utilities list does not have a context menu.
4. When editing income for budgets, on iOS & iPadOS (compact mode), there is no way to put in all fields for the income. A close look was added.
5. On iOS, or iPadOS (compact), there is no comma on the composite transaction.

### Level 4 - Unusable
1. When deleting an income division, the app would crash. This issue was investigated, a fix was not found, and then it stopped happening. If it occurs again, please report this issue.
***Note***: This is a beta version. Data format is not guaranteed to be persistent across versions. 

## New Features
1. Added a payday transaction template. This pulls from the jobs information, and will auto-populate the estimate of your paycheck. 
2. Removed sub-accounts and sub-categories. All transactions under some (Account, Sub Account) and (Category, Sub Category) pair will be moved directly under the account and category. All user interface locations for account/sub-account and category/sub-category pairs have been removed to just account or category.
3. Moved income divisions to be the income of a budget. To add income divisions, go to a budget, and add them there. You still edit the devotions using the Income Division tool. 
4. Modified the internal data storage to have better consistency and updates from the user interface. 
5. Changed categories to have an additional property: Description. This can help you identify what your categories are for. Additionally, categories now have a separate editor and inspector.
6. Redesigned the Categories tool to include more information about categories. 
7. Completed documentation. 
8. Added ***bill history***. This feature allows you to record how much was spent on a bill over time. One can use this to help record when bills were paid. As you use the Bill/Subscription/Utility payment, you can put in this amount.
9. Since bill and utility history dates are automatically calculated, there wasn't support for gaps in payments. For this reason, the ability to mark a specific due date as skipped is now possible. 
10. Budgets goals got an additional property: Periods. This period can be weekly, bi-weekly, or monthly. This allows you to set specific goals for shorter periods. Edmund will do the math and compute what you need per month to meet that goal. 

## Notes
1. The home-screen's "Scroll" mode was removed in favor of "Compact" mode. The compact mode shows two widgets vertically. 
2. The upcoming bills widget has been redesigned for both macOS, iOS, and iPadOS. On macOS, the widget is displayed as a table, showing the bill, amount, and due date. On iOS/iPadOS, the bill name and the due date are shown only. 
## Bug Fixes
### Level 1 - Cosmetic
1. Corrected the issue where on iOS and iPadOS (compact mode), the welcome sometimes shows above the home-screen widgets.
2. On category inspect and edit, the "Description" label was positioned incorrectly.
3. On category edit, the name did not have a border on iOS/iPadOS.
4. Changed the homescreen to help with glitches. Glitches still occur on iOS, but you can move back to the homescreen and the glitch will go away.
5. On the ledger in iOS, or iPadOS, the footer totals was crammed. It is fixed by only showing the total balance instead of all details. 
6. Fixed an internal issue with payday transaction template.

### Level 2 - Minor Annoyance
1. Corrected an issue where, despite the user's choice of "Subscription" or "Bill", the add bill tool always defaults to the "Bill" kind. 
2. Corrected an issue that occurs when opening the budget tool in a separate window. The window used to say: "Work in progress". 
3. On macOS, if one used the transaction templates menu under the Ledger menu, no editor would appear. This has been fixed. 
4. The initial balance transaction template did not allow for negative starting balances. 

### Level 3 - Noticeable Issues
1. The budget tool did not add up transactions correctly, so budgets for a month were not accurate. 
2. Fixed an issue where many-to-many transfer did not accept correctly balanced.

### Level 4 - Unusable 
1. A bug was reported when adding a budget month. This issue should be resolved.


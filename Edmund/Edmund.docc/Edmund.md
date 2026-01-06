# ``Edmund``

A modern, simple, and consistent budgeting app, aimed at helping individuals learn and keep financial literacy. 

## Topics

### Understanding Edmund 
- <doc:Project-Layout>
- <doc:Type-Groups>

### Elements and Element Representation
A series of mostly protocols that define what an "Element" is. At a basical level, an element is an identifiable class that exhibits specific properties or behaviors.
- ``ElementBase``
- ``DefaultableElement``
- ``IsolatedDefaultableElement``
- ``NamedElement``
- ``VoidableElement``
- ``TransactionHolder``
- ``InspectableElement``
- ``EditableElement``
- ``NamedElement``
- ``NamedVisualizer``
- ``Displayable``
- ``DisplayableVisualizer``
- ``TypeTitled``
- ``TypeTitleStrings``
- ``TypeTitleVisualizer``

### Element Selection, Inspection, Editing, Deleting, and Adding
Elements can be handled by the UI through selection, inspection, editing, deleting and adding. Naturally, Edmund presents a series of tools to aid in these processes. Note that this "selection" refers directly to picking a single element (via a context menu), and should not be confused with Edmund's Selection system (listed below).
- ``InspectionState``
- ``InspectionManifest``
- ``ElementInspectButton``
- ``WithInspectorModifier``
- ``ElementInspector`` 
- ``ElementEditButton``
- ``ElementAddButton``
- ``EditableElementManifest``
- ``ElementEditManifest``
- ``ElementAddManifest``
- ``ElementSelectionMode``
- ``ElementEditor``
- ``ElementIE``
- ``WithInspectorModifier``
- ``SwiftUICore/View/withElementInspector(manifest:)``
- ``WithEditorModifier``
- ``SwiftUICore/View/withElementEditor(manifest:using:filling:post:)``
- ``WithInspectorEditorModifier``
- ``SwiftUICore/View/withElementIE(manifest:using:filling:post:)``
- <doc:Editing,-Selecting,-and-Adding-Elements>
- ``ElementPicker``
- ``DeletingManifest``
- ``DeletingActionConfirm``
- ``ElementDeleteButton``
- ``DeleteConfirmModifier``
- ``SwiftUICore/View/withElementDeleting(manifest:post:)``
- <doc:Deleting-Elements>
- ``SelectionContextMenu``
- ``SingularContextMenu``
- <doc:Context-Menus>

### Selection
Tools for picking data out of the UI through interactive states.
- ``SelectionContextProtocol``
- ``SelectionContext``
- ``FrozenSelectionContext``
- ``QuerySelection``
- ``FilterableQuerySelection``
- ``SourcedSelection``
- <doc:Using-Selection>

### Time
Tools relating to time and calculations thereof.
- ``MonthlyTimePeriods``
- ``TimePeriods``
- ``TimePeriodWalker``
- ``MonthYear``


### Transaction, Balances, and Grouping
All things dealing with specific stores or uses of currency. 
- ``Account``
- ``AccountKind``
- ``Envolope``
- ``AccountLocator``
- ``Category``
- ``CategoriesContext``
- ``SwiftUICore/EnvironmentValues/categoriesContext``
- ``LedgerEntry``
- ``BalanceEncoder``
- ``BalanceInformation``
- ``SimpleBalance``
- ``DetailedBalance``
- ``BalanceResolver``


### Bills & Invoices
Information regarding recurring payments to another institution. 
- ``Bill``
- ``BillDatapoint``
- ``ResolvedBillHistory``
- ``BillDatapointSnapshot``
- ``BillsKind``
- ``BillsKind``
- ``UpcomingBill``
- ``UpcomingBillsBundle``
- ``UpcomingBillsComputation``
- ``AllBillsViewEdit``
- ``AllExpiredBillsVE``
- ``BillEdit``
- ``BillInspect``
- ``BillDatapointEdit``
- ``BillDatapointInspect``
- ``BillDatapointGraph``

### Budgets and Weath Management
Tooling for handling money, as it both enters and leaves your personal finances. 
- ``Budget``
- ``BudgetGoal``
- ``BudgetSpendingGoal``
- ``BudgetSavingsGoal``
- ``IncomeDivision``
- ``IncomeDevotion``
- ``AmountDevotion``
- ``PercentDevotion``
- ``RemainderDevotion``
- ``DevotionGroup``
- ``IncomeKind``

### Income
Looking at the specific ways that money comes into your finances.
- ``IncomeSource``
- ``TraditionalJob``
- ``HourlyJob``
- ``SalariedJob``

### Homepage
Information presented to the user at first launch.
- ``Homepage``
- ``WidgetChoice``
- ``MajorHomepageOrder``
- ``MinorHomepageOrder``
- ``SplitKind``
- ``ChoiceRenderer``
- ``SplitChoiceRenderer``
- ``MoneyGraph``
- ``SimpleBalancesView``
- ``SpendingGraph``
- ``SpendingGraphMode``
- ``SpendingComputation``
- ``UpcomingBillsView``
- ``HomepageEditor``
- ``ChoicePicker``
- ``SplitChoicePicker``

### Data Management
Overall management of the Core Data system that Edmund's backend uses.
- ``DataStack``
- ``ContainerDataFiller``
- ``DebugContainerFiller``
- ``DebugSampleData``

### App Loading
The tools responsible for constructing and setting up the backend for Edmund.
- ``EdmundApp``
- ``LoadedAppContext``
- ``AppLoadErrorKind``
- ``AppLoadError``
- ``AppState``
- ``AppLoadingState``
- ``AppLoaderEngine``
- ``SwiftUICore/EnvironmentValues/appLoader``
- ``AppWindowGate``
- ``AppErrorView``

### Core UI 
The main UI of the app and top of the view hiearchy. 
- ``MainView``
- ``PageDestinationWrapper``
- ``PageDestinations``
- ``AboutView``
- ``SettingsView``

### App Help Tools
A series of structures, classes, and actors that present and manage the help guides for Edmund's users. 
- ``TopicFetchError``
- ``GroupFetchError``
- ``ResourceLoadState``
- ``TopicLoadState``
- ``GroupLoadState``
- ``ResourceLoadHandleBase``
- ``ResourceLoadHandle``
- ``WholeTreeLoadHandle``
- ``HelpResourceID``
- ``HelpResourceCore``
- ``UnloadedHelpResource``
- ``HelpTopic``
- ``HelpGroup``
- ``HelpResource``
- ``HelpEngine``
- ``LoadedHelpTopic``
- ``TopicLoadHandle``
- ``TopicRequest``
- ``LoadedHelpGroup``
- ``LoadedHelpResource``
- ``HelpResourcePresenter``
- ``GroupLoadHandle``
- ``TopicGroupPresenter`` 
- ``HelpTreePresenter``
- ``TopicPagePresenter``
- ``TopicErrorView``
- ``TopicPresenter``
- ``TopicButtonStyle``
- ``HelpPresenterView``
- ``TopicButtonBase``
- ``TopicButton``
- ``TopicGroupButton``
- ``TopicBaseToolbarButton``
- ``TopicToolbarButton``
- ``TopicGroupToolbarButton``

### App Helpers
Systems that are presented to the whole app and carry extra information or functionality.
- ``LoggerSystem``
- ``SwiftUICore/EnvironmentValues/loggerSystem``
- ``ElementLocator``
- ``LimitedQueue``
- ``LimitedQueueIterator``

### UI Tools
Various tools presented to the UI.
- ``EnumPicker``
- ``NullableValue``
- ``NullableValueBacking``
- ``LoadableView``
- ``ShakeEffect``
- ``TooltipButton``
- ``NumericalValueEntry``
- ``CurrencyField``
- ``PercentField``
- ``DuplicateNameError``
- ``LocaleCurrencyCode``
- ``ThemeMode``
- ``ValidationFailure``

### UI State
Tools related to the presentation of information to the user, or information carried through the app.
- ``SwiftUICore/EnvironmentValues/pagesLocked``
- ``SwiftUI/FocusedValues/currentPage``
- ``WarningBasis``
- ``SelectionWarningKind``
- ``StringWarning``
- ``InternalErrorWarning``
- ``WarningManifest``
- ``SelectionWarningManifest``
- ``StringWarningManifest``
- ``ValidationWarningManifest``
- ``InternalWarningManifest``
- ``WarningManifestExtension``
- ``SwiftUICore/View/withWarning(_:)``

### Edmund Information
Various information used by the UI.
- ``bugFormLink``
- ``featureFormLink``

### Widget Tools
Tools historically used to process data for widgets. This may be used in the future, but currently is unused besides protocol conformance.
- ``WidgetDataBundle``
- ``ProcessedData``
- ``WidgetDataEngine``
- ``WidgetDataProvider``

# My Expense

A comprehensive expense tracking application built with Flutter, designed to help users monitor their spending habits through various timeframes and visual insights.

## Features

- **Dashboard Overview**: Visualize your expenses with intuitive time-based views:
  - **Daily**: See what you've spent today.
  - **Weekly**: Track spending over the current week.
  - **Monthly**: Keep an eye on your monthly budget.
  - **Yearly**: Review your annual financial health.
- **Add Expenses**: Quickly record new expenses with details like amount, date, time, and category.
- **Visual Analytics**: Interactive charts powered by `fl_chart` to visualize spending trends.
- **Local Persistence**: All data is stored securely on the device using `hive`, ensuring offline access and privacy.
- **Efficient State Management**: Uses `provider` for a responsive and seamless user experience.

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: Dart
- **State Management**: [provider](https://pub.dev/packages/provider)
- **Local Database**: [hive](https://pub.dev/packages/hive) & [hive_flutter](https://pub.dev/packages/hive_flutter)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Date Formatting**: [intl](https://pub.dev/packages/intl)
- **Utilities**: [uuid](https://pub.dev/packages/uuid), [path_provider](https://pub.dev/packages/path_provider)

## Getting Started

Follow these steps to set up the project locally:

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd track_expenses
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate code:**
    This project uses Hive code generation. Run the build runner to generate necessary adapters:
    ```bash
    dart run build_runner build
    ```

4.  **Run the application:**
    ```bash
    flutter run
    ```

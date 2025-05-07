# Cleanslate

Cleanslate is a Flutter-based application designed to provide a clean and efficient starting point for building cross-platform applications. It is a template project that helps developers quickly set up and customize their Flutter apps for Android, iOS, web, and macOS.

## Features

- **Cross-Platform Support**: Build and run the app on Android, iOS, web, and macOS.
- **Customizable UI**: Pre-configured launch screens and themes for Android and iOS.
- **Web Support**: Includes a web manifest file and favicon setup for web deployment.
- **Efficient Build Setup**: Custom build directory configuration for better project organization.
- **Scalable Architecture**: A clean and modular structure to help scale the app as it grows.

## Getting Started

This project is a starting point for a Flutter application.

### Prerequisites

- Install [Flutter](https://docs.flutter.dev/get-started/install) on your system.
- Set up your development environment for [Android](https://docs.flutter.dev/get-started/install/macos#android-setup), [iOS](https://docs.flutter.dev/get-started/install/macos#ios-setup), or [web](https://docs.flutter.dev/get-started/web).

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd cleanslate
   ```
2. Install dependencies:
    ```bash
    flutter pub get
    ```

3. Run the app:
    ```bash
    flutter run
    ```

## Folder Structure

The project follows a modular folder structure for better organization:

```
cleanslate/
├── lib/
│   ├── main.dart         # Entry point of the application
│   ├── screens/          # Contains all the screen widgets
│   ├── widgets/          # Reusable UI components
│   ├── models/           # Data models
│   ├── services/         # Business logic and API integrations
│   └── utils/            # Utility functions and constants
├── assets/               # Static assets like images and fonts
├── test/                 # Unit and widget tests
└── pubspec.yaml          # Project configuration file
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix:
    ```bash
    git checkout -b feature-name
    ```
3. Commit your changes:
    ```bash
    git commit -m "Add feature-name"
    ```
4. Push to your branch:
    ```bash
    git push origin feature-name
    ```
5. Open a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions or feedback, feel free to reach out at [imsounic@gmail.com].
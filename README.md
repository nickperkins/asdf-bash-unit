# asdf-bash-unit

This project is an asdf plugin for managing versions of [Bash Unit](https://github.com/BashUnit/BashUnit), a testing framework for Bash scripts. This plugin allows users to easily install, manage, and switch between different versions of Bash Unit.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Available Versions](#available-versions)
- [Contributing](#contributing)
- [License](#license)

## Installation

To install the Bash Unit asdf plugin, run the following command:

```bash
asdf plugin-add bash-unit https://github.com/nickperkins/asdf-bash-unit.git
```

## Usage

Once the plugin is installed, you can install a specific version of Bash Unit using:

```bash
asdf install bash-unit <version>
```

To set a global version of Bash Unit, use:

```bash
asdf global bash-unit <version>
```

To set a local version for a specific project, run:

```bash
asdf local bash-unit <version>
```

## Available Versions

To list all available versions of Bash Unit that can be installed through this plugin, use:

```bash
asdf list-all bash-unit
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
# Developing LAVA in VS Code

This guide provides instructions for developing the LAVA R package using Visual Studio Code, particularly when working on a remote machine.

## Required Extensions

Install the following VS Code extensions:

1. **R Extension for VS Code** - Main R language support
2. **R Debugger** - For debugging R code
3. **radian** - An alternative R console

## Setup

### 1. Configure R in VS Code

1. Open VS Code settings (File > Preferences > Settings)
2. Search for "r.rterm" and set the path to your R executable
   - On Windows: Usually `C:\\Program Files\\R\\R-4.x.x\\bin\\R.exe`
   - On Mac: Usually `/usr/local/bin/R` or `/Library/Frameworks/R.framework/Resources/bin/R`
   - On Linux: Usually `/usr/bin/R`

### 2. Configure R Language Server

For better code intelligence:

1. Install the languageserver package in R:
   ```r
   install.packages("languageserver")
   ```
2. In VS Code settings, enable R language server

### 3. Working with Remote Machines

When working on a remote machine:

1. Install the **Remote - SSH** extension in VS Code
2. Connect to your remote server via SSH
3. Open the LAVA project folder on the remote machine
4. VS Code will use the R installation on the remote machine

## Development Workflow

### Building Documentation

To generate documentation from roxygen comments:

1. Open the VS Code terminal
2. Run:
   ```r
   devtools::document()
   ```

### Running Tests

To run tests:

1. Open the VS Code terminal
2. Run:
   ```r
   devtools::test()
   ```

### Building the Package

To build the package:

1. Open the VS Code terminal
2. Run:
   ```r
   devtools::build()
   ```

### Checking the Package

To check the package:

1. Open the VS Code terminal
2. Run:
   ```r
   devtools::check()
   ```

### Building the Website

To build the pkgdown website:

1. Open the VS Code terminal
2. Run:
   ```r
   pkgdown::build_site()
   ```

## Debugging in VS Code

1. Install the R Debugger extension
2. Set breakpoints in your code
3. Use the VS Code debugger to step through your code

## Keyboard Shortcuts

Some useful keyboard shortcuts when working with R in VS Code:

- `Ctrl+Enter` (Windows/Linux) or `Cmd+Enter` (Mac): Run the current line or selection
- `Ctrl+Shift+S` (Windows/Linux) or `Cmd+Shift+S` (Mac): Run the current source file

## Recommended Workflow for Remote Development

1. Develop locally for quick iterations
2. Periodically push changes to GitHub
3. On the remote machine, pull from GitHub
4. Run comprehensive tests and checks on the remote machine
5. Build documentation and website on the remote machine

## Troubleshooting

### Common Issues with R in VS Code

1. **R executable not found**: Check your r.rterm setting in VS Code
2. **Language server not working**: Ensure languageserver package is installed
3. **Cannot run code interactively**: Check that an R terminal is active

### Remote Development Issues

1. **Slow connection**: Consider using VS Code's workspace sync feature
2. **Git authentication**: Set up SSH keys for seamless GitHub authentication
3. **File permission issues**: Check file permissions on the remote machine

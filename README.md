# NOC Shift Automation

Desktop automation for a Windows-based Network Operations Center (NOC).

The project automates the repetitive tasks performed at the beginning and end of every workday: establishing a VPN connection, preparing browser-based monitoring tools, authenticating internal web applications, sending shift status messages to a team chat and shutting everything down in the correct order.

Built for my own daily use at a regional ISP, the project focuses on reliability rather than automation for its own sake. The goal was not simply to automate repetitive tasks, but to make the automation reliable enough to be trusted every working day. Most of the implementation exists to handle failure scenarios. Although developed for my own setup, the design principles of state verification, direct CLI integration, DOM based browser automation and selecting the most appropriate integration point for each application are applicable well beyond this project.

> **Security Notice**
>
> All hostnames, IP addresses and credentials in this repository are placeholders. IP addresses use the RFC 5737 documentation ranges instead of real internal infrastructure.

---

# Features

### Startup automation

* Connects to Cisco AnyConnect VPN
* Verifies VPN establishment and network availability
* Launches required applications
* Opens browser-based monitoring dashboards
* Authenticates supported internal web applications
* Sends a predefined shift-start message

### Shutdown automation

* Closes applications in a controlled order
* Sends a predefined shift-end message
* Disconnects the VPN cleanly

---

# Architecture

| Component                     | Responsibility                                                                       |
| ----------------------------- | ------------------------------------------------------------------------------------ |
| `boot/Autoconnect.ahk`        | Morning chain: VPN, softphone, Chrome and its six dashboards, shift message          |
| `shutdown/Autodisconnect.ahk` | Controls the shutdown automation                                                     |
| `vpn/VpnConnect.ps1`          | Establishes the headless VPN connection                                              |
| `vpn/VpnDriver.ps1`           | Drives the VPN CLI by reading its console buffer and injecting keystrokes            |
| `vpn/VpnDisconnect.ps1`       | Disconnects the VPN cleanly                                                          |
| `chrome-extension/`           | Manifest V3 extension that logs the browser dashboards in from inside the page DOM   |

---

# Engineering decisions

## Interactive CLI instead of GUI automation

Cisco AnyConnect provides an interactive CLI that is considerably more reliable than automating the graphical client.
The project communicates directly with the CLI, handling certificate confirmation and authentication without depending on window focus or desktop interaction.

---

## Browser automation inside the DOM

Instead of simulating keyboard input, browser dashboard authentication is implemented as a Manifest V3 Chrome Extension.
Working directly with the page DOM makes the automation resilient to browser focus changes, popup windows and expired sessions while avoiding many of the limitations of traditional UI automation.

---

## State verification instead of fixed delays

The automation does not simply wait a predefined number of seconds before continuing.
Each stage verifies that the expected state has been reached before moving to the next one, for example:

* VPN connected
* Network available
* Dashboard accessible
* Correct team chat selected

Only then does execution continue.
This approach makes the automation significantly more reliable than scripts based on fixed sleep intervals.

---

## Clean VPN shutdown

The VPN is disconnected using the client's normal shutdown procedure rather than terminating the underlying service.
This allows Cisco AnyConnect to correctly remove routes, DNS configuration and network filters before Windows returns to its normal network state.

---

# Tech Stack

- AutoHotkey v2
- PowerShell 5.1 (P/Invoke into `kernel32` and `advapi32`)
- JavaScript (Chrome Extension, Manifest V3)
- UI Automation
- Windows Task Scheduler
- Windows Credential Manager
- Cisco AnyConnect CLI

---

# Limitations

- Credentials stored in the extension are placeholders for this public repository. A real trade-off: Chrome only installs extensions from the Web Store on a non-managed machine and publishing an extension full of internal dashboard passwords is not an option.
- It is loaded unpacked on a single user Windows environment, where anything that can read the file already has the logged-in session. This belongs behind an enterprise policy or a credential broker.
- Install paths, monitor layout and dashboard configuration are environment-specific.
- It automates UIs, so it inherits their fragility. Browser and desktop automation depend on application behavior and may require adjustments after major software updates.
- Both scripts log to `Documents`, which is the first place to look when a step misbehaves.

# local_auth_platform_interface

A common platform interface for the [`local_auth`][1] plugin.

This interface allows platform-specific implementations of the `local_auth`
plugin, as well as the plugin itse
`LocalAuthPlatform.instance = MyLocalAuthPlatform()`.

# Note on breaking changes

Strongly prefer non-breaking changes (such as adding a method to the interface)
over breaking changes for this package.

See https://flutter.dev/go/platform-interface-breaking-changes for a discussion
on why a less-clean interface is preferable to a breaking change.

[1]: ../local_auth
[2]: lib/local_auth_platform_interface.dart

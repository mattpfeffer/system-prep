# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [1.1.2] - 2020-11-13
### Added
- Support for TLS 1.3 in NGINX config
- Test file generation in web root

### Changed
- Load third party modules in 'core' package when building NGINX (rather than 'common')
- Use lighter NGINX 'core' instead of 'full'

### Fixed
- Incorrect PHP-FPM version in NGINX config stubs

## [1.1.1] - 2020-11-09
### Changed
- Minor references and commands to support changes related to Ubuntu 20.04 release

## [1.1.0] - 2019-09-23
- Initial release

[Unreleased]: https://github.com/mattpfeffer/system-prep/compare/v1.0.0...HEAD
[1.1.2]: https://github.com/mattpfeffer/system-prep/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/mattpfeffer/system-prep/compare/v1.1.0...v1.1.1
[1.0.0]: https://github.com/olivierlacan/keep-a-changelog/releases/tag/v1.1.0

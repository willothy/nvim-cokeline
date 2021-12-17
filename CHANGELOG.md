# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog], and this project adheres to
[Semantic Versioning].

## [Unreleased]

## [0.1.0] - 2021-12-07

### Added

- Started using Semantic Versioning, added this Changelog.
- Added config option `buffers.filter_valid`
  ([#29](https://github.com/noib3/nvim-cokeline/issues/29)).
- Highlights defined in `default_hl` can now accept a function taking a
  `buffer` as parameter to compute their values, just like the ones in
  `components` ([#23](https://github.com/noib3/nvim-cokeline/issues/23)).
- Added GitHub Actions test to make sure no line of code exceeds 79 characters.

### Changed

- Renamed config option `cycle_prev_next_mappings` to
  `mappings.cycle_next_prev`.
- Renamed config option `buffers.filter` to
  `buffers.filter_visible`.
- Renamed config option `rendering.max_line_width` to
  `rendering.max_buffer_width`.
- Default value for `mappings.cycle_next_prev` is now `true` instead of
  `false`.
- Updated the help file and the `README.md`.
- Rewrote almost the entire plugin in a more functional style.

### Fixed

- Fixed an issue where opening multiple buffers at the same time with
  `buffers.new_buffers_position = 'next'` would cause them to be displayed in
  the opposite order of what they should be
  ([#22](https://github.com/noib3/nvim-cokeline/issues/22#issuecomment-975955018)).

### Removed

- Removed config option `rendering.min_line_width`, which hadn't been
  implemented anyway.

[Semantic Versioning]: https://semver.org/spec/v2.0.0.html
[Keep a changelog]: https://keepachangelog.com/en/1.0.0/

[unreleased]: https://github.com/noib3/nvim-cokeline/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/noib3/nvim-cokeline/releases/tag/v0.1.0

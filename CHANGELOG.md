## 0.5.1:
- Refactoring

## 0.5.0:
- Supported engine version is now atom-1.13 or later
- Fix: Remove of use of `text-editor::shadow`.
- Breaking, Improve:
  - Tweak flash style: Make it subtle, and flash by CSS keyframe animation.
  - Deprecate `flashDurationMilliSeconds` setting. It's now 1 sec static.
- Internal: Refactoring code.

## 0.4.0:
- Write spec
- Bug fix: `defaultWordGroupExcludeScope` was not respected.

## 0.3.2:
- Update default wordGroup.

## 0.3.1:
- Add notification for removal of `flashColor` setting.
- Update gif in readme since it is based on old behavior when special char(`@`) is supported.

## 0.3.0
- Remove `flashOnToggle` setting.
- Remove `flashColor` setting.
- Refactoring: rewrite all part of codes.
- Improve accuracy for picking word under cursor.
- Remove support of word including special char. Now word must match `\w+`.

## 0.2.3 - Improve
- README.md TODO update
- Update readme to follow vim-mode's command-mode to normal-mode

## 0.2.2 - Improve
- New Flash on toggle feature (now default).
- Use atom-config-plus.
- Use `activationCommands` for faster startup time..
- Update gif.
- Refactoring.

## 0.2.1 - Fix, Improve
- [BUG] Infinit loop at EOF.
- Don't toggl word if word is same.
- [experimental] Add more default word group.

## 0.2.0 - Improve
- Remove dev statge=Alpha phrase from README.md
- Support language specific keyword handling
- Disable default words group by configuration.
- `there`, `visit`.
- User configuration and auto-reload on save.

## 0.1.0 - First Release
